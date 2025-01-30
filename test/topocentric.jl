@testsnippet setup_topocentric begin
    using SatcomCoordinates: numbertype, to_svector, raw_nt, @u_str
    using SatcomCoordinates.LinearAlgebra
    using SatcomCoordinates.StaticArrays
    using SatcomCoordinates.BasicTypes
    using TestAllocations
end

@testitem "ENU/NED" setup=[setup_topocentric] begin
    for P in (ENU, NED)
        @test numbertype(P(1,2,3)) == Float64
        @test numbertype(P{Float32}(1,2,3)) == Float32

        @test P(1,2,3) == P((1,2,3)) == P(SA[1,2,3])

        @test_throws "do not have a property" rand(P).q

        @test rand(P) isa P{Float64}
        @test rand(P{Float32}) isa P{Float32}

        @test isnan(ENU(1, 2, NaN))

        @test convert(P{Float32}, rand(P)) isa P{Float32}

        p1, p2 = rand(P, 2)
        @test p1 ≉ p2
        @test p1 ≈ p1
        @test p1 ≈ convert(P{Float32}, p1)
    end

    enu = rand(ENU)
    @test enu.x === enu.east
    @test enu.y === enu.north
    @test enu.z === enu.up

    ned = rand(NED)
    @test ned.x === ned.north
    @test ned.y === ned.east
    @test ned.z === ned.down

    @testset "Allocations" begin
        @test @nallocs(ENU(1,2,3)) == 0
        @test @nallocs(ENU{Float32}(1,2,3)) == 0
        @test @nallocs(ENU(SVector(1f0,2f0,3f0))) == 0

        @test @nallocs(NED(1,2,3)) == 0
        @test @nallocs(NED{Float32}(1,2,3)) == 0
        @test @nallocs(NED(SVector(1f0,2f0,3f0))) == 0
    end
end

@testitem "AER" setup=[setup_topocentric] begin
    @test numbertype(AER(1,2,3)) == Float64
    @test numbertype(AER{Float32}(1,2,3)) == Float32

    @test AER(190°, 90, 1000u"m") == AER(-170°, 90°, 1000u"m")

    @test_throws "do not have a property" rand(AER).q

    @test rand(AER) ≉ rand(AER)
    aer = rand(AER)
    @test aer ≈ aer

    @test aer.azimuth == aer.az
    @test aer.elevation == aer.el
    @test aer.range == aer.r

    @testset "Allocations" begin
        @test @nallocs(AER(1,2,3)) == 0
        @test @nallocs(AER{Float32}(1,2,3)) == 0
    end
end

@testitem "Conversion" setup=[setup_topocentric] begin
    valid_types = (ENU, NED, AER)
    for P in valid_types
        for Q in valid_types
            p = rand(P)
            q = convert(Q, p)
            @test p ≈ q
            @test p ≈ convert(P, q)
        end
    end
end
