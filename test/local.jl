@testsnippet setup_local begin
    using SatcomCoordinates
    using SatcomCoordinates: numbertype, raw_svector, raw_properties, @u_str, has_pointingtype, pointing_type
    using SatcomCoordinates.LinearAlgebra
    using SatcomCoordinates.StaticArrays
    using SatcomCoordinates.BasicTypes
    using SatcomCoordinates.Rotations
    using TestAllocations
end

@testitem "LocalCartesian" setup=[setup_local] begin
    @test LocalCartesian(1,2,3) == LocalCartesian(SA[1,2,3])
    @test numbertype(rand(LocalCartesian)) == Float64
    @test numbertype(rand(LocalCartesian{Float32})) == Float32

    @test numbertype(LocalCartesian((1,2.0,3))) == Float64
    @test numbertype(LocalCartesian(1f0,2f0,3f0)) == Float32

    @test isnan(LocalCartesian(1,2,NaN))

    @test convert(LocalCartesian{Float32}, rand(LocalCartesian)) isa LocalCartesian{Float32}
    @test convert(LocalCartesian, rand(LocalCartesian{Float32})) isa LocalCartesian{Float32}
    @test convert(LocalCartesian{Float64}, rand(LocalCartesian{Float32})) isa LocalCartesian{Float64}

    p1, p2 = rand(LocalCartesian, 2)
    @test p1 ≉ p2
    @test p1 ≈ p1
    @test p1 ≈ convert(LocalCartesian{Float32}, p1)

    @testset "Allocations" begin
        @test @nallocs(LocalCartesian(1,2,3)) == 0
        @test @nallocs(LocalCartesian{Float32}(1,2,3)) == 0
        @test @nallocs(LocalCartesian(SVector(1f0,2f0,3f0))) == 0
    end

    c1, c2 = rand(LocalCartesian, 2)
    @test raw_svector(c1 + c2) == raw_svector(c1) + raw_svector(c2)
    @test raw_svector(c1 - c2) == raw_svector(c1) - raw_svector(c2)

    c3 = rand(LocalCartesian{Float32})
    @test c1 + c3 isa LocalCartesian{Float64}
    @test c1 - c3 isa LocalCartesian{Float64}
end

@testitem "GeneralizedSpherical" setup=[setup_local] begin
    @test Spherical(1,2,3) isa GeneralizedSpherical{Float64, ThetaPhi{Float64}}
    @test Spherical{Float32}(1,2,3) isa GeneralizedSpherical{Float32, ThetaPhi{Float32}}


    s = rand(Spherical)
    @test s.r == s.range == s.distance
    @test s.θ == s.theta == s.pointing.θ
    @test s.φ == s.phi == s.pointing.φ

    @test !isnan(s)
    @test isnan(Spherical(Val{NaN}()))

    @test AzElDistance(1,2,3) isa GeneralizedSpherical{Float64, AzEl{Float64}}
    @test AzElDistance{Float32}(1,2,3) isa GeneralizedSpherical{Float32, AzEl{Float32}}

    g = rand(GeneralizedSpherical{Float32, ElOverAz{Float32}})
    @test g.pointing isa ElOverAz{Float32}

    @test g.az == g.azimuth == g.pointing.az
    @test g.el == g.elevation == g.pointing.el
    @test g.r == g.range == g.distance

    @testset "Allocations" begin
        @test @nallocs(Spherical(1,2,3)) == 0

        @test @nallocs(getproperty(rand(Spherical), :pointing)) == 0
        @test @nallocs(getproperty(rand(Spherical), :theta)) == 0
        @test @nallocs(getproperty(rand(Spherical), :phi)) == 0

        @test @nallocs(raw_properties(rand(Spherical))) == 0
        @test @nallocs(raw_properties(rand(AzElDistance))) == 0
    end

    @test GeneralizedSpherical{Float32}(rand(ThetaPhi), rand()) isa Spherical{Float32}
    @test GeneralizedSpherical(rand(ThetaPhi{Float32}), rand(Float32)) isa Spherical{Float32}
    @test GeneralizedSpherical(rand(ThetaPhi), rand(Float32)) isa Spherical{Float64}
    @test GeneralizedSpherical(rand(ThetaPhi{Float32}), rand(Float64)) isa Spherical{Float64}

    @test !has_pointingtype(GeneralizedSpherical)
    @test !has_pointingtype(GeneralizedSpherical{Float64})
    @test has_pointingtype(GeneralizedSpherical{Float64, ThetaPhi{Float64}})
    @test has_pointingtype(Spherical)
    @test has_pointingtype(AzElDistance)

    @test pointing_type(rand(Spherical)) == ThetaPhi{Float64}
    @test pointing_type(Spherical) == ThetaPhi
    @test pointing_type(AzElDistance) == AzEl

    @test_throws "No pointing type can be uniquely inferred from GeneralizedSpherical" pointing_type(GeneralizedSpherical)
    @test_throws "No pointing type can be uniquely inferred from GeneralizedSpherical" pointing_type(GeneralizedSpherical{Float64})
    @test pointing_type(GeneralizedSpherical{Float64, ThetaPhi{Float64}}) == ThetaPhi{Float64}

    p = rand(Spherical)
    @test raw_properties(p) isa NamedTuple{(:θ, :φ, :r), Tuple{Float64, Float64, Float64}}

    for PT in (ThetaPhi, AzEl, ElOverAz, AzOverEl)
        gs = rand(GeneralizedSpherical{Float64, PT{Float64}})
        @test convert(LocalCartesian, -gs) ≈ -convert(LocalCartesian, gs)
    end
end


@testitem "Conversions" setup=[setup_local] begin
    PTs = map(Iterators.product((ThetaPhi, AzEl, ElOverAz, AzOverEl), (Float32, Float64))) do (P, T)
        GeneralizedSpherical{T, P{T}}
    end

    for PT in PTs
        g = rand(PT)
        l = convert(LocalCartesian, g)
        @test g ≈ l
        @test convert(PT, l) ≈ g rtol = 1e-4
        for PT2 in PTs
            f = convert(PT2, g)
            @test f isa PT2
            @test f ≈ g
            @test convert(PT, f) ≈ g rtol = 1e-4
        end
    end

end