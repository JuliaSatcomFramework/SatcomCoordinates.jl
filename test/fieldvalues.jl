@testsnippet setup_fieldvalues begin
    using SatcomCoordinates
    using SatcomCoordinates.Unitful
    using SatcomCoordinates.Unitful
    using SatcomCoordinates.BasicTypes
    using SatcomCoordinates.StaticArrays
    using Test
    using TestAllocations
end

@testitem "FieldValues" setup=[setup_fieldvalues] begin
    const U = typeof(u"m/s")
    const D = dimension(u"m/s")

    const V{T} = Quantity{T, D, U}

    struct VelocityFieldValue{CRS <: AbstractPosition{<:Any, 3}, T} <: AbstractFieldValue{U, CRS, T}
        svector::SVector{3, T}

        BasicTypes.constructor_without_checks(::Type{VelocityFieldValue{CRS, T}}, sv::SVector{3, T}) where {CRS, T} = new{CRS, T}(sv)
    end

    @test_throws "must not contain the numbertype"  VelocityFieldValue{ECEF{Float64}}(1,2,3)
    @test_throws "but should have 3 elements"  VelocityFieldValue{ECEF}(1,2,3, 4)

    fv = VelocityFieldValue{ECEF}(1, 2, 3)

    @test fv.x == 1u"m/s"
    @test fv.y == 2u"m/s"
    @test fv.z == 3u"m/s"

    @test raw_svector(fv) == SVector{3, Float64}(1, 2, 3)
    @test raw_properties(fv) == (x=1, y=2, z=3)

    struct ComplexUnitlessFieldValue{CRS <: AbstractPosition{<:Any, 3}, T <: Complex} <: AbstractFieldValue{typeof(NoUnits), CRS, T}
        svector::SVector{3, T}

        BasicTypes.constructor_without_checks(::Type{ComplexUnitlessFieldValue{CRS, T}}, sv::SVector{3, T}) where {CRS, T <: Complex} = new{CRS, T}(sv)
    end

    SatcomCoordinates.enforce_numbertype(C::Type{<:ComplexUnitlessFieldValue}) = enforce_numbertype(C, Complex{Float64})

    svu = @SVector rand(Complex{Float64}, 3)
    fvu = ComplexUnitlessFieldValue{Spherical}(svu)

    @test raw_svector(fvu) == svu

    @test fvu.θ  == svu[1]
    @test fvu.φ  == svu[2]
    @test fvu.r  == svu[3]

    @testset "Allocations" begin
        @test @nallocs(raw_svector(fv)) == 0
        @test @nallocs(getproperty(fv, :x)) == 0

        @test @nallocs(raw_svector(fvu)) == 0
        @test @nallocs(getproperty(fvu, :θ)) == 0
    end
end