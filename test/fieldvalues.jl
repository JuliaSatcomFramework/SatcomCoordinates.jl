@testsnippet setup_fieldvalues begin
    using SatcomCoordinates
    using SatcomCoordinates.Unitful
    using SatcomCoordinates.StaticArrays
    using Test
end

@testitem "FieldValues" setup=[setup_fieldvalues] begin
    const U = typeof(u"m/s")
    const D = dimension(u"m/s")

    const V{T} = Quantity{T, D, U}

    struct VelocityFieldValue{T, CRS <: CartesianPosition{T, 3}} <: AbstractFieldValue{T, 3, CRS, V{T}}
        svector::SVector{3, V{T}}
    end

    sv = map(x -> x * u"m/s", SVector{3, Float64}(1, 2, 3))

    fv = VelocityFieldValue{Float64, ECEF{Float64}}(sv)

    @test fv.x == 1u"m/s"
    @test fv.y == 2u"m/s"
    @test fv.z == 3u"m/s"
    @test fv.svector == sv
end
