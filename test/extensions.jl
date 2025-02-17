@testsnippet setup_extensions begin
    using SatcomCoordinates
    using SatcomCoordinates: normalized_properties, normalized_svector
    using Test
    using TestAllocations
end

@testitem "SatelliteToolboxBase Extension" setup=[setup_extensions] begin
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

@testitem "SatelliteToolboxTransformations Extension" setup=[setup_extensions] begin
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
    ecef = geodetic_to_ecef(LLA(0,0,0)) |> normalized_svector
    @test ecef ≈ [WGS84_ELLIPSOID.a, 0, 0]

    ecef = geodetic_to_ecef(LLA(90,0,0)) |> normalized_svector
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

@testitem "CountriesBorders Extension" setup=[setup_extensions] begin
    using SatcomCoordinates: SatcomCoordinates, Deg
    using CountriesBorders: CountriesBorders, LATLON, LatLon, extract_countries

    lla_rome = LLA(41.9°, 12.5°, 0km)
    lla_madrid = LLA(40.416°, -3.703°)

    ll_rome = LatLon(lla_rome)
    @test ll_rome.lat ≈ change_numbertype(Float32, lla_rome).lat
    @test ll_rome.lon ≈ change_numbertype(Float32, lla_rome).lon

    ll_rome_F64 = convert(LATLON{Float64}, lla_rome)
    @test ll_rome_F64.lat ≈ lla_rome.lat
    @test ll_rome_F64.lon ≈ lla_rome.lon

    @test LLA(ll_rome_F64) ≈ lla_rome

    dmn = extract_countries("italy")

    @test lla_rome in dmn
    @test lla_madrid ∉ dmn
end