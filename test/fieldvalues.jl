@testsnippet setup_fieldvalues begin
    using SatcomCoordinates
    using SatcomCoordinates.Unitful
    using SatcomCoordinates.StaticArrays
    using Test
    using TestAllocations
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

    @test normalized_svector(fv) == map(ustrip, sv)

    struct ComplexFieldValue{T, CRS <: AbstractPosition{T, 3}} <: AbstractFieldValue{T, 3, CRS, Complex{T}}
        svector::SVector{3, Complex{T}}
    end

    svu = @SVector rand(Complex{Float64}, 3)
    fvu = ComplexFieldValue{Float64, Spherical{Float64}}(svu)

    @test normalized_svector(fvu) == svu

    @test fvu.θ == fvu.theta == svu[1]
    @test fvu.ϕ == fvu.phi == svu[2]
    @test fvu.r == fvu.range == svu[3]
    @test fvu.svector == svu

    @testset "Allocations" begin
        @test @nallocs(normalized_svector(fv)) == 0
        @test @nallocs(getproperty(fv, :x)) == 0
        @test @nallocs(getproperty(fv, :svector)) == 0

        @test @nallocs(normalized_svector(fvu)) == 0
        @test @nallocs(getproperty(fvu, :θ)) == 0
        @test @nallocs(getproperty(fvu, :svector)) == 0
    end
end