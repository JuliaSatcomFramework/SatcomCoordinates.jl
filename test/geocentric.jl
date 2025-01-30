@testsnippet setup_geocentric begin
    using SatcomCoordinates: numbertype, to_svector, raw_nt, @u_str
    using SatcomCoordinates.LinearAlgebra
    using SatcomCoordinates.StaticArrays
    using SatcomCoordinates.BasicTypes
    using TestAllocations
end

@testitem "ECEF/ECI" setup=[setup_geocentric] begin
    for P in (ECEF, ECI)
        @test numbertype(P(1,2,3)) == Float64
        @test numbertype(P{Float32}(1,2,3)) == Float32

        @test P(1,2,3) == P((1,2,3)) == P(SA[1,2,3])

        @test rand(P) isa P{Float64}
        @test rand(P{Float32}) isa P{Float32}

        @test isnan(ECEF(1, 2, NaN))

        @test convert(P{Float32}, rand(P)) isa P{Float32}

        p1, p2 = rand(P, 2)
        @test p1 ≉ p2
        @test p1 ≈ p1
        @test p1 ≈ convert(P{Float32}, p1)
    end
    @test_throws "Cannot compare coordinates of different types" rand(ECEF) ≈ rand(ECI)
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

    @test rand(LLA) ≉ rand(LLA)

    lla = rand(LLA)
    @test lla.lat == lla.latitude
    @test lla.lon == lla.longitude
    @test lla.alt == lla.altitude == lla.h == lla.height

    @testset "Allocations" begin
        @test @nallocs(LLA(0,0,700km)) == 0
        @test @nallocs(LLA(0°,0,700km)) == 0
        @test @nallocs(LLA(0,0,700e3)) == 0
    end
end