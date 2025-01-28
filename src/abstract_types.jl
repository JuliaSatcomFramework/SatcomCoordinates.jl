"""
    AbstractSatcomCoordinate{T, N}

General abstract type identifying a _coordinate_ with `N` dimensions and an underlying number type `T`. The number type `T` is not necessarily the type of the fields in the type instance, but the underlying real type of the fields (this is used for Unitful quantities, such that `numbertype(::Quantity{T}) where T = T`).

!!! note
    The term _coordinate_ is used here in a loose sense, identifying both position in space as well as pointing directions
"""
abstract type AbstractSatcomCoordinate{T, N} end

"""
    CartesianPosition{T, N} <: AbstractSatcomCoordinate{T, N}

Abstract type representing a coordinate in `N` dimensions which is backed by
fields all of type `T`. 
Concrete subtypes of this are subtypes of `FieldVector`
"""
abstract type CartesianPosition{T, N} <: AbstractSatcomCoordinate{T, N} end
abstract type LengthCartesian{T, N} <: CartesianPosition{T, N} end

abstract type AbstractPointing{T, N} <: AbstractSatcomCoordinate{T, N} end

"""
    AngularPointing{T}

Abstract type representing a pointing direction identified by two angles in
degrees, represented with fields of types `Deg{T}`.
"""
abstract type AngularPointing{T} <: AbstractPointing{T, 2} end
