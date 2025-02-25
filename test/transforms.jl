@testsnippet setup_transforms begin
    using SatcomCoordinates
    using SatcomCoordinates: numbertype, normalized_svector, normalized_properties, @u_str, has_pointingtype, pointing_type, rotation, origin, AbstractCRSRotation
    using SatcomCoordinates.LinearAlgebra
    using SatcomCoordinates.StaticArrays
    using SatcomCoordinates.BasicTypes
    using SatcomCoordinates.Rotations
    using SatcomCoordinates.TransformsBase: TransformsBase, inverse, parameters, Identity, isinvertible, isrevertible, →
    using TestAllocations

    apply(t, args...) = TransformsBase.apply(t, args...) |> first
    apply(t) = Base.Fix1(apply, t)
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
    RotationNaN = (a = rand(3,3); a[1] = NaN; a) |> RotMatrix3 |> CRSRotation

    @test !isnan(t)
    @test !isnan(r)
    @test isnan(RotationNaN)

    AffineNaN = BasicCRSTransform(R, LocalCartesian(NaN, NaN, NaN))
    @test isnan(AffineNaN)


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

    fwd = apply(t, p)
    rvs = apply(inverse(t), fwd)
    @test rvs ≈ p

    # Getproperty
    i = inverse(t)
    @test i.transform === t
    @test i.rotation === t.rotation
    @test i.origin === t.origin

    @test !isnan(i)
    @test isnan(AffineNaN |> inverse)

    @testset "Allocations" begin
        @test @nallocs(apply(t, p)) == 0
        @test @nallocs(apply(inverse(t), p)) == 0
    end

    t = BasicCRSTransform(Identity(), zero(LocalCartesian))
    @test rotation(t) === Identity() === rotation(Identity())
    @test p ≈ apply(t, p)

    r1, r2 = rand(CRSRotation, 2)
    r3 = r1 → r2
    p1 = p |> apply(r1) |> apply(r2)
    p2 = p |> apply(r3)
    @test p1 ≈ p2

    # Convert
    @test convert(CRSRotation, r1) === r1
    @test convert(CRSRotation{Float64}, r1) === r1
    @test convert(CRSRotation{Float32}, r1) !== r1

    @test convert(BasicCRSTransform, t) === t
    @test convert(BasicCRSTransform{Float64}, t) === t
    @test convert(BasicCRSTransform{Float32}, t) !== t

    @test convert(InverseTransform, inverse(t)) === inverse(t)
    @test convert(InverseTransform{Float64}, inverse(t)) === inverse(t)
    @test convert(InverseTransform{Float32}, inverse(t)) !== inverse(t)

    @testset "AbstractCRSTransform" begin
        if !eval(:(@isdefined MyRotation))
            eval(:(struct MyRotation <: AbstractCRSRotation{Float64}
                rotation::CRSRotation{Float64, RotMatrix3{Float64}}
            end))
        end
        MyRotation = eval(:MyRotation)

        r = MyRotation(rand(RotMatrix3{Float64}) |> CRSRotation)

        @test !isnan(r)
        @test isnan(MyRotation(RotationNaN))

        p = rand(LocalCartesian)
        a1 = apply(r, p)
        a2 = apply(r.rotation, p)
        @test a1 ≈ a2
        @test apply(inverse(r), a1) ≈ p
    end
end


