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

        @test rand(P) isa P{Float64}
        @test rand(P{Float32}) isa P{Float32}

        @test isnan(ENU(1, 2, NaN))

        @test convert(P{Float32}, rand(P)) isa P{Float32}

        p1, p2 = rand(P, 2)
        @test p1 ≉ p2
        @test p1 ≈ p1
        @test p1 ≈ convert(P{Float32}, p1)
    end
    @test_throws "Cannot compare coordinates of different types" rand(ENU) ≈ rand(NED)
end

@testitem "AER" setup=[setup_topocentric] begin
    @test numbertype(AER(1,2,3)) == Float64
    @test numbertype(AER{Float32}(1,2,3)) == Float32

    
end