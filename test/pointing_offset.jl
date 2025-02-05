@testsnippet setup_pointing_offsets begin
    using SatcomCoordinates
    using SatcomCoordinates: numbertype, to_svector, raw_nt, @u_str, has_pointingtype, pointing_type, rotation, origin, UVOffset, ThetaPhiOffset
    using SatcomCoordinates.LinearAlgebra
    using SatcomCoordinates.StaticArrays
    using SatcomCoordinates.BasicTypes
    using SatcomCoordinates.BasicTypes: constructor_without_checks
    using SatcomCoordinates.Rotations
    using TestAllocations
end

@testitem "Pointing Offsets" setup=[setup_pointing_offsets] begin
    uv1, uv2 = rand(UV, 2)
    uv_offset = uv1 - uv2
    @test uv_offset isa UVOffset
    @test uv2 + uv_offset ≈ uv1

    @test uv_offset == UVOffset(uv_offset.u, uv_offset.v)

    @test uv_offset.inner isa UV
    @test uv_offset.inner.u === uv_offset.u
    @test uv_offset.inner.v === uv_offset.v

    tp1, tp2 = rand(ThetaPhi, 2)
    tp_offset = get_angular_offset(tp1, tp2)
    @test tp_offset isa ThetaPhiOffset
    @test tp2 ≈ add_angular_offset(tp1, tp_offset)

    @test tp_offset.inner isa ThetaPhi
    @test tp_offset.inner.θ === tp_offset.t === tp_offset.θ
    @test tp_offset.inner.φ === tp_offset.p === tp_offset.φ

    @test rand(UVOffset) isa UVOffset
    @test rand(ThetaPhiOffset) isa ThetaPhiOffset
    @test rand(UVOffset{Float32}) isa UVOffset{Float32}
    @test rand(ThetaPhiOffset{Float32}) isa ThetaPhiOffset{Float32}

    @test tp_offset == ThetaPhiOffset(tp_offset.t, tp_offset.p) == constructor_without_checks(ThetaPhiOffset{Float64}, tp_offset.t, tp_offset.p)
end

@testitem "angular distance/offset" setup=[setup_pointing_offsets] begin
    p1 = ThetaPhi(0, rand() * 360°)
    p2 = ThetaPhi(90, rand() * 360°)
    @test get_angular_distance(p1, p2) ≈ 90°

    valid_types = (ThetaPhi, AzOverEl, ElOverAz, UV, PointingVersor, AzEl)
    @test all(1:100) do _
        p1 = rand(rand(valid_types))
        p2 = rand(rand(valid_types))
        θ = get_angular_distance(p1, p2)
        o = get_angular_offset(p1, p2)
        θ ≈ o.θ
    end

    @test all(1:100) do _
        p1 = rand(rand(valid_types))
        p2 = rand(rand(valid_types))
        o = get_angular_offset(p1, p2)
        if p1 isa UV && convert(PointingVersor, p2).z < 0
            return true # We skip or we would get an error for negative z half hemisphere
        else
            return p2 ≈ add_angular_offset(p1, o)
        end
    end

    p = rand(ThetaPhi)
    @test add_angular_offset(p, 10°) == add_angular_offset(p, ThetaPhi(10°, 0))
    @test add_angular_offset(p, 10°, 20°) == add_angular_offset(p, ThetaPhi(10°, 20°))

    @test all(valid_types) do O
        p = rand(O <: UV ? UV : rand(valid_types))
        o = add_angular_offset(O, p, 0.0°)
        o isa O && o ≈ p
    end

    @testset "Allocations" begin
        @test @nallocs(add_angular_offset(rand(UV), 0.0°)) == 0
        @test @nallocs(add_angular_offset(rand(PointingVersor), rand(ThetaPhi))) == 0
        @test @nallocs(add_angular_offset($ThetaPhi, ThetaPhi(10,0), 0.0°)) == 0
    end

    # Error
    @test_throws "behind" add_angular_offset(UV(1,0), ThetaPhi(10,0))
end