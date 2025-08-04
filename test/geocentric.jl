@testsnippet setup_geocentric begin
    using SatcomCoordinates: WGS84_PARAMS, _ellipsoidparams, ncoords
    using SatcomCoordinates.LinearAlgebra
    using SatcomCoordinates.StaticArrays
    using SatcomCoordinates.BasicTypes
    using SatcomCoordinates.Rotations
    using SatcomCoordinates.TransformsBase: TransformsBase, inverse, isinvertible, isrevertible
    using TestAllocations
    using SatcomCoordinates
    using Test
end

@testitem "ECEF/ECI" setup=[setup_geocentric] begin
    for P in (ECEF, ECI)
        @test valuetype(P(1,2,3)) == Float64
        @test valuetype(P(1,2,3) |> change_valuetype(Float32)) == Float32

        @test P(1,2,3) == P()((1,2,3)) == P()(SA[1,2,3])

        @test rand(P()) isa Coordinate{<:P, Float64}

        @test isnan(ECEF(1, 2, NaN))

        p1, p2 = rand(P(), 2)
        @test p1 ≉ p2
        @test p1 ≈ p1
        @test p1 ≈ change_valuetype(Float32, p1)

        @test P((1,2,3)) == P(1,2,3)

        # Error method for ambiguities
        @test_throws "does not match" P(1)
        @test_throws "does not match" P(1, 2)
    end
    @test_throws "are not equivalent" rand(ECEF()) ≈ rand(ECI())

    @testset "Allocations" begin
        @test @nallocs(ECEF(1,2,3)) == 0
        @test @nallocs(ECEF()(SA[1,2,3])) == 0
        @test @nallocs(ECEF(1,2,3) |> change_valuetype(Float32)) == 0
    end

    # We do a transform between ECEF/ECI with a random ID. It should error because we don't have a rotation method
    @test_throws "no method is defined" change_crs(ECEF(:s), ECI(:p)(1,2,3))
    # We test that if we pass the matrix explicitly, this actually works
    ecef = change_crs(ECEF(:s), ECI(:p)(1,2,3); R_eci_to_ecef = one(RotMatrix3))
    @test ecef isa Coordinate{ECEF{Symbol}}
    @test SVector(Raw(ecef)) ≈ SA_F64[1,2,3]
end

@testitem "LLA" setup=[setup_geocentric] begin
    @test LLA(10°, 10°, 1000) ≈ LLA((10 + 100 * eps()) * °, 10°, 1000)
    @test LLA(90°, 10°, 1000) ≈ LLA(90°, 130°, 1000)
    @test LLA(40°, -180°, 1000) ≈ LLA(40°, 180°, 1000)
    @test LLA(40°, -180°, 1000) ≈ LLA(40, 180, 1000)
    @test LLA(40°, 180°, 1000) == LLA(40, 180, 1000)
    @test LLA(0°, 0°, 0km) ≈ LLA(1e-5°, 0°, 0km)
    @test LLA(0°, 0°, 0km) ≈ LLA(1e-5°, 1e-5°, 1e-6km)
    @test LLA(0°, 0°, 0km) ≉ LLA(1.1e-5°, 0°, 0km)
    @test LLA(0°, 0°, 0km) ≉ LLA(1e-5°, 1e-5°, 1.1e-6km)
    @test LLA(10°, 10°, 1000) !== LLA((10 + 100 * eps()) * °, 10°, 1000)
    @test isnan(LLA(1, 1, NaN))
    @test_throws "atol" isapprox(LLA(0°, 0°, 0km), LLA(1e-5°, 1e-5°, 1e-6km); atol=0.2)

    @test_throws "latitude" LLA(91°, 20°)
    @test_nowarn LLA(90°, 20°)
    @test_nowarn LLA(0, 10°, 10u"m")
    @test_nowarn LLA(0, 10°, 10u"km")
    @test_nowarn LLA(1°, .1, 10u"km")

    @test rand(LLA()) ≉ rand(LLA())

    lla = rand(LLA())
    @test lla.lat isa Deg
    @test lla.lon isa Deg
    @test lla.alt isa Met

    @test_throws "not a valid property" lla.q

    @testset "Allocations" begin
        @test @nallocs(LLA(0,0,700km)) == 0
        @test @nallocs(LLA(0°,0,700km)) == 0
        @test @nallocs(LLA(0,0,700e3)) == 0
    end

    # Mostly coverage on the LLA/ECEF Transform
    t = getcrstransform_raw(linkedcrs, LLA())
    it = inverse(t)
    @test t == inverse(it)

    ncoords(t) == 3

    TransformsBase.parameters(t) == (; id = EarthDefault())
    @test isinvertible(t) && isrevertible(t)
    @test isinvertible(it) && isrevertible(it)
end

@testitem "ellipsoidparams" setup=[setup_geocentric] begin
    @test ellipsoidparams(EarthDefault()) == WGS84_PARAMS

    (; a, f ) = WGS84_PARAMS
    @test _ellipsoidparams(a, f) == WGS84_PARAMS
end

@testitem "frameid" setup=[setup_geocentric] begin
    @test frameid(ECEF()) == EarthDefault()
    @test frameid(ECI()) == EarthDefault()
    @test frameid(LLA()(1,2,3)) == EarthDefault()
    aff_ecef = AffineCartesian(Cartesian(), ECEF(), rand(RawAffineTransform))
    aff_eci = AffineCartesian(Cartesian(), ECI(), rand(RawAffineTransform))
    @test frameid(aff_ecef) == frameid(aff_eci) == EarthDefault()
    @test_throws "does not seem to contain a frame id" frameid(Cartesian())
end