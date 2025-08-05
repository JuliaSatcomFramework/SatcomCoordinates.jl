@testsnippet setup_topocentric begin
    using SatcomCoordinates: WGS84_PARAMS, have_same_origin
    using SatcomCoordinates.LinearAlgebra
    using SatcomCoordinates.StaticArrays
    using SatcomCoordinates.BasicTypes
    using SatelliteToolboxTransformations
    using TestAllocations
    using Test
end

@testitem "ENU/NED" setup=[setup_topocentric] begin
    for P in (ENU, NED)
        topo_crs = P(LLA(0,0,1200km))
        @test topo_crs == P(change_crs(ECEF(), LLA(0,0,1200km)))
        @test valuetype(topo_crs) == Float64
        @test valuetype(change_valuetype(Float32, topo_crs)) == Float32

        # Test different coord constructors
        coord = topo_crs(1,2,3)

        @test coord == topo_crs((1,2,3)) == topo_crs(SA[1,2,3])

        @test_throws "is not a valid property" rand(topo_crs).q

        @test isnan(topo_crs(1, 2, NaN))

        p1, p2 = rand(topo_crs, 2)
        @test p1 ≉ p2
        @test p1 ≈ p1
    end

    enu = ENU(LLA(0,0,1200km))(1,2,3)
    @test enu.x == enu.e == enu.east == 1u"m"
    @test enu.y == enu.n == enu.north == 2u"m"
    @test enu.z == enu.u == enu.up == 3u"m"

    ned = NED(LLA(0,0,1200km))(1,2,3)
    @test ned.x == ned.n == ned.north == 1u"m"
    @test ned.y == ned.e == ned.east == 2u"m"
    @test ned.z == ned.d == ned.down == 3u"m"

    @testset "Allocations" begin
        ned_crs = getcrs(ned)
        enu_crs = getcrs(enu)
        @test @nallocs(change_crs(enu_crs, ned)) == 0
        @test @nallocs(change_crs(ned_crs, enu)) == 0
        # Going to ECEF
        @test @nallocs(change_crs(ECEF(), ned)) == 0
        @test @nallocs(change_crs(ECEF(), enu)) == 0
        # Going to LLA
        @test @nallocs(change_crs(LLA(), ned)) == 0
        @test @nallocs(change_crs(LLA(), enu)) == 0

        # Construction
        @test @nallocs(NED(LLA(0,0,1200km))) == 0
        @test @nallocs(ENU(LLA(0,0,1200km))) == 0
        # Coordinate construction
        @test @nallocs(NED(LLA(0,0,1200km))(1,2,3)) == 0
        @test @nallocs(ENU(LLA(0,0,1200km))(1,2,3)) == 0
    end

    # ECEF/LLA origin
    ned_crs = NED(LLA(0,0,1200km))
    ned = ned_crs(1,2,3)
    aer_crs = AER(lla_origin(ned_crs))
    @test ecef_origin(ned_crs) == ecef_origin(ned) == ecef_origin(aer_crs)
    @test lla_origin(ned_crs) == lla_origin(ned) == lla_origin(aer_crs)

    # Errors
    @test_throws "A topocentric CRS could not be found" ecef_origin(rand(Cartesian()))
    @test_throws "A topocentric CRS could not be found" lla_origin(rand(Cartesian()))

    # Different origin errors
    ned_crs = NED(LLA(0,0,1200km))
    enu_crs = ENU(LLA(10,0,1200km))
    @test_throws "have different origins" change_crs(enu_crs, ned_crs(1,2,3))

    # Different linked CRS errors
    SatcomCoordinates.ellipsoidparams(::Symbol) = WGS84_PARAMS
    SatcomCoordinates.is_same_crs(crs1::ECEF{Symbol}, crs2::ECEF{Symbol}) = frameid(crs1) == frameid(crs2)
    invokelatest() do
        ned_crs = NED(LLA(ECEF(:B))(0,0,1200km))
        enu_crs = ENU(LLA(ECEF(:S))(0,0,1200km))
        @test_throws "different linked CRSs" change_crs(ned_crs, enu_crs(1,2,3))

        # We test coverage
        @test !have_same_origin(NED(LLA(ECEF(:B))(0,0,1200km)), ENU(LLA(0,0,1200km)))
    end

    # Construction error with wrong coordinate trait
    @test_throws "origin of the $NED CRS must be associated with an ECEF or LLA CRS" NED(rand(Cartesian()))
end

@testitem "AER" setup=[setup_topocentric] begin
    aer_crs = AER(LLA(0,0,1200km))
    @test valuetype(aer_crs) == Float64

    # We test wrapping of the angles
    @test aer_crs(190°, 90, 1000u"m") == aer_crs(-170°, 90°, 1u"km")

    @test_throws "is not a valid property" rand(aer_crs).q

    @test rand(aer_crs) ≉ rand(aer_crs)
    aer = aer_crs(10, 20, 1u"km")
    @test aer ≈ aer


    @test aer.az == aer.azimuth == 10u"°"
    @test aer.el == aer.elevation == 20u"°"
    @test aer.r == aer.distance == aer.range == 1000u"m"

    ae = rand(aer_crs)
    enu_crs = getcrs(cartesiancrs, ae)
    @test change_crs(enu_crs, -ae) ≈ -change_crs(enu_crs, ae)

    @testset "Allocations" begin
        @test @nallocs(AER(LLA(0,0,1200km))(1,2,3)) == 0
        aer_crs = AER(LLA(0,0,1200km))
        @test @nallocs(change_crs(aer_crs, LLA(0,0,1200km))) == 0
    end

    # Ambiguities errors
    @test_throws "does not have a custom implementation of a no-argument constructor" AER(1)
    @test_throws "does not have a custom implementation of a no-argument constructor" AER((1, 2))

    @test contains(repr(aer_crs), "AER")
end

@testitem "Conversion" setup=[setup_topocentric] begin
    valid_types = (ENU, NED, AER)
    lla = LLA(0,0,1200km)
    for P in valid_types
        for Q in valid_types
            p = rand(P(lla))
            q = change_crs(Q(lla), p)
            p′ = change_crs(P(lla), q)
            @test p ≈ p′
        end
    end
end
