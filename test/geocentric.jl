@testsnippet setup_geocentric begin
    using SatcomCoordinates.LinearAlgebra
    using SatcomCoordinates.StaticArrays
    using SatcomCoordinates.BasicTypes
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
    end
    @test_throws "are not equivalent" rand(ECEF()) ≈ rand(ECI())

    @testset "Allocations" begin
        @test @nallocs(ECEF(1,2,3)) == 0
        @test @nallocs(ECEF()(SA[1,2,3])) == 0
        @test @nallocs(ECEF(1,2,3) |> change_valuetype(Float32)) == 0
    end
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
end