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
    AbstractFieldValue{T, N, CRS <: AbstractPosition{T, N}, F}

Abstract type representing the value of a physical field expressed in a specific `CRS` in `N` dimensions with numbertype `T`.

A method of `property_aliases` is defined for this abstract type that simply returns `property_aliases(CRS)`.

Default concrete implementations of this subtype are expected to have a single inner field `svector` which is a `SVector{N, F}` to exploit the `raw_properties` method defined on this abstract type.

An example concrete type representing velocity in a 3D CRS can be implemented as follows (assuming to have `Quantity`, `@u_str` and `dimension` imported from `Unitful`):

```julia
struct VelocityFieldValue{T, CRS <: CartesianPosition{T, 3}} <: AbstractFieldValue{T, 3, CRS, Quantity{T, dimension(u"m/s"), typeof(u"m/s")}}
    svector::SVector{3, Quantity{T, dimension(u"m/s"), typeof(u"m/s")}}
end
```

# Concrete subtypes
`SatcomCoordinates.jl` currently does not implement concrete subtypes of `AbstractFieldValue`, but only defines the following methods: 
- `raw_properties(::AbstractFieldValue{T, N, CRS, F})`: Assumes that the concrete subtype has a field called `svector` which is an `SVector{N, F}`
- `property_aliases(::Type{<:AbstractFieldValue{T, N, CRS}})`: Simply returns `property_aliases(CRS)`
- `raw_svector(::AbstractFieldValue)`: Assumes that the concrete subtype has a field called `svector` and simply returns it, eventually stripping the units from the elements if they are of type `Quantity`.
- `Base.getproperty(::AbstractFieldValue, ::Symbol)`: Based on the same `@generated` function used for objects of type `AbstractSatcomCoordinate` and requiring `property_aliases` and `raw_properties` to be defined for the concrete subtype.
"""
abstract type AbstractFieldValue{CRS, F} end