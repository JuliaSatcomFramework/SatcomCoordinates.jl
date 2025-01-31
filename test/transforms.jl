@testsnippet setup_transforms begin
    using SatcomCoordinates
    using SatcomCoordinates: numbertype, to_svector, raw_nt, @u_str, has_pointingtype, pointing_type, rotation, origin
    using SatcomCoordinates.LinearAlgebra
    using SatcomCoordinates.StaticArrays
    using SatcomCoordinates.BasicTypes
    using SatcomCoordinates.Rotations
    using SatcomCoordinates.TransformsBase: apply, inverse, parameters, Identity, isinvertible, isrevertible
    using TestAllocations
end

@testitem "CRS Transforms" setup=[setup_transforms] begin
    @test rand(CRSRotation) isa CRSRotation{Float64}
    @test rand(CRSRotation{Float32}) isa CRSRotation{Float32}

    @test rand(BasicCRSTransform) isa BasicCRSTransform{Float64}
    @test rand(BasicCRSTransform{Float32}) isa BasicCRSTransform{Float32}

    p = rand(LocalCartesian)

    R = rand(SMatrix{3, 3})
    t = BasicCRSTransform(R, rand(LocalCartesian))
    r = CRSRotation(R)

    @test norm(R) ≉ norm(r.rotation) ≈ sqrt(3)

    @test rotation(r) === r

    @test isrevertible(t)
    @test isinvertible(t)

    nt = parameters(t |> rotation)
    @test nt.rotation isa RotMatrix3

    nt = parameters(t)
    @test nt.rotation === rotation(t)
    @test nt.origin === origin(t)

    @test t === inverse(inverse(t))
    @test inverse(rotation(t)) === rotation(inverse(t))

    ff(t, x) = apply(t, x) |> first
    fwd = ff(t, p)
    rvs = ff(inverse(t), fwd)
    @test rvs ≈ p

    @testset "Allocations" begin
        @test @nallocs(ff(t, p)) == 0
        @test @nallocs(ff(inverse(t), p)) == 0
    end

    t = BasicCRSTransform(Identity(), zero(LocalCartesian))
    @test rotation(t) === Identity() === rotation(Identity())
    @test p ≈ ff(t, p)
end
