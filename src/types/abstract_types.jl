"""
    AbstractSatcomCoordinate{T, N}

General abstract type identifying a _coordinate_ with `N` dimensions and an underlying number type `T`. The number type `T` is not necessarily the type of the fields in the type instance, but their underlying real type (this is only different for fields whose types are Unitful quantities, where `numbertype(::Quantity{T}) where T = T`).

!!! note
    The term _coordinate_ is used here in a loose sense, identifying both position in space as well as pointing directions
"""
abstract type AbstractSatcomCoordinate{T, N} end

abstract type AbstractPosition{T, N} <: AbstractSatcomCoordinate{T, N} end

"""
    AbstractPointing{T} <: AbstractSatcomCoordinate{T, 3}

Abstract type representing a pointing direction in 3 dimensions which is backed by fields with shared [`numbertype`](@ref) `T`.
"""
abstract type AbstractPointing{T} <: AbstractSatcomCoordinate{T, 3} end

"""
    AbstractLocalPosition{T} <: AbstractPosition{T, 3}

Abstract type representing a position in a local coordinate system.
"""
abstract type AbstractLocalPosition{T, N} <: AbstractPosition{T, N} end

"""
    AbstractTopocentricPosition{T} <: AbstractPosition{T, 3}

Abstract type representing a position in a topocentric coordinate system.
"""
abstract type AbstractTopocentricPosition{T} <: AbstractPosition{T, 3} end

"""
    AbstractGeocentricPosition{T} <: AbstractPosition{T, 3}

Abstract type representing a position in a geocentric coordinate system.
"""
abstract type AbstractGeocentricPosition{T} <: AbstractPosition{T, 3} end

"""
    AngularPointing{T}

Abstract type representing a pointing direction identified by two angles in
degrees, represented with fields of types `Deg{T}`.
"""
abstract type AngularPointing{T} <: AbstractPointing{T} end

"""
    AbstractPointingOffset{T} <: AbstractSatcomCoordinate{T, 2}

Abstract type representing a pointing offset between two pointing directions.

Currently only has two concrete subtypes: [`UVOffset`](@ref) and [`ThetaPhiOffset`](@ref).
"""
abstract type AbstractPointingOffset{T} <: AbstractSatcomCoordinate{T, 2} end

"""
    AbstractCRSTransform{T}

Abstract type representing a coordinate transform between two CRSs with numbertype `T`.
"""
abstract type AbstractCRSTransform{T} <: Transform end

"""
    AbstractAffineCRSTransform{T}

Abstract type representing an affine transform between two CRSs with numbertype `T`.
"""
abstract type AbstractAffineCRSTransform{T} <: AbstractCRSTransform{T} end

"""
    AbstractFieldValue{U, CRS, T}

Abstract type representing the value of a physical field expressed in a specific coordinate reference system `CRS`, and whose components have an associated unit `U` and a numbertype `T`.

Concrete implementations of this subtype are expected to have a single inner field `svector` which is a `SVector{N, T}` (`N` being the number of dimensions of the referenced `CRS`) and define the `BasicTypes.constructor_without_checks` method as per other coordinates in order to exploit the convenience functions defined on this abstract type.

An example concrete type representing velocity in a 3D CRS can be implemented as follows (assuming to have `Quantity`, `@u_str` and `dimension` imported from `Unitful`, and `SVector` from StaticArrays):

```julia
const U = typeof(u"m/s")
const D = dimension(u"m/s")

const V{T} = Quantity{T, D, U}

struct VelocityFieldValue{CRS <: AbstractPosition{<:Any, 3}, T} <: AbstractFieldValue{U, CRS, T}
    svector::SVector{3, T}

    BasicTypes.constructor_without_checks(::Type{VelocityFieldValue{CRS, T}}, sv::SVector{3, T}) where {CRS, T} = new{CRS, T}(sv)
end

fv = VelocityFieldValue{ECEF}(1, 2, 3)

@test fv.x == 1u"m/s"
@test fv.y == 2u"m/s"
@test fv.z == 3u"m/s"

@test raw_svector(fv) == SVector{3, Float64}(1, 2, 3)
@test raw_properties(fv) == (x=1, y=2, z=3)
```

# Concrete subtypes
`SatcomCoordinates.jl` currently does not implement concrete subtypes of `AbstractFieldValue`, but only defines the following methods that work if concrete subtypes are impelemented as in the example above: 
- `raw_svector(::AbstractFieldValue)`: Returns the `svector` field
- `raw_properties(::AbstractFieldValue)`: Returns a NamedTuple with the properties of the `svector` field
- `properties_names(::Type{<:AbstractFieldValue{U, CRS}})`: Returns the property names of the `CRS` parametric type
- Default constructor taking `N` numbers or a Tuple/Svector, with the values interpreted as quantities of unit `U` if not provided directly as quantitites
- `ConstructionBase.getproperties(::AbstractFieldValue{U, CRS})`: Returns a NamedTuple with the properties of the field assuming the properties names of `CRS` and returning values with unit `U`. 
- `Base.getproperty`: extraction of properties directly from the NamedTuple returned by `ConstructionBase.getproperties`
"""
abstract type AbstractFieldValue{U <: Units, CRS, T} end