@testsnippet setup_extensions begin
    using SatcomCoordinates
    using SatcomCoordinates: raw_nt, to_svector
    using Test
    using TestAllocations
end

@testitem "SatelliteToolboxBaseExt" setup=[setup_extensions] begin
    using SatelliteToolboxBase: SatelliteToolboxBase, Ellipsoid, WGS84_ELLIPSOID
    
    e = Ellipsoid(6371e3, 0)
    @test e isa Ellipsoid{Float64}
    @test change_numbertype(Float32, e) isa Ellipsoid{Float32}
    @test change_numbertype(Float64, e) === e

    @testset "Allocations" begin
        @test @nallocs(change_numbertype($Float32, e)) == 0
        @test @nallocs(change_numbertype($Float64, e)) == 0
    end
end

@testitem "SatelliteToolboxTransformationsExt" setup=[setup_extensions] begin
    using SatelliteToolboxBase: Ellipsoid, WGS84_ELLIPSOID
    using SatelliteToolboxTransformations: geodetic_to_ecef, ecef_to_geodetic

    e = Ellipsoid(6371e3, 0)

    # Test default WGS84_ELLIPSOID
    @test geodetic_to_ecef(rand(LLA{Float64})) isa ECEF{Float64}
    @test geodetic_to_ecef(rand(LLA{Float32})) isa ECEF{Float32}

    @test ecef_to_geodetic(rand(ECEF{Float64})) isa LLA{Float64}
    @test ecef_to_geodetic(rand(ECEF{Float32})) isa LLA{Float32}

    # Test with custom ellipsoid
    @test geodetic_to_ecef(rand(LLA{Float64}), ellipsoid=e) isa ECEF{Float64}
    @test geodetic_to_ecef(rand(LLA{Float32}), ellipsoid=e) isa ECEF{Float32}

    @test ecef_to_geodetic(rand(ECEF{Float64}), ellipsoid=e) isa LLA{Float64}
    @test ecef_to_geodetic(rand(ECEF{Float32}), ellipsoid=e) isa LLA{Float32}

    # Some test for specific values
    ecef = geodetic_to_ecef(LLA(0,0,0)) |> to_svector
    @test ecef ≈ [WGS84_ELLIPSOID.a, 0, 0]

    ecef = geodetic_to_ecef(LLA(90,0,0)) |> to_svector
    @test ecef ≈ [0, 0, WGS84_ELLIPSOID.b]

    # Test some random fwd and rtn equivalence
    @test all(1:100) do _
        lla = rand(LLA)
        ecef = geodetic_to_ecef(lla)
        lla′ = ecef_to_geodetic(ecef)
        lla ≈ lla′
    end

    @testset "Allocations" begin
        @test @nallocs(geodetic_to_ecef(rand(LLA{Float64}))) == 0
        @test @nallocs(geodetic_to_ecef(rand(LLA{Float32}))) == 0

        @test @nallocs(geodetic_to_ecef(rand(LLA{Float64}); ellipsoid=e)) == 0
        @test @nallocs(geodetic_to_ecef(rand(LLA{Float32}); ellipsoid=e)) == 0

        @test @nallocs(ecef_to_geodetic(rand(ECEF{Float64}))) == 0
        @test @nallocs(ecef_to_geodetic(rand(ECEF{Float32}))) == 0

        @test @nallocs(ecef_to_geodetic(rand(ECEF{Float64}); ellipsoid=e)) == 0
        @test @nallocs(ecef_to_geodetic(rand(ECEF{Float32}); ellipsoid=e)) == 0
    end
end