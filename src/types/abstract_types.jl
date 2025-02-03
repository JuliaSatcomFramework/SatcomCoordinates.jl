"""
    AbstractSatcomCoordinate{T, N}

General abstract type identifying a _coordinate_ with `N` dimensions and an underlying number type `T`. The number type `T` is not necessarily the type of the fields in the type instance, but their underlying real type (this is only different for fields whose types are Unitful quantities, where `numbertype(::Quantity{T}) where T = T`).

!!! note
    The term _coordinate_ is used here in a loose sense, identifying both position in space as well as pointing directions
"""
abstract type AbstractSatcomCoordinate{T, N} end

abstract type AbstractPosition{T, N} <: AbstractSatcomCoordinate{T, N} end

"""
    AngleAngleDistance{T} <: AbstractSatcomCoordinate{T, 3}

Abstract type representing a position in 3 dimensions, identified by two angles and a distance.
"""
abstract type AngleAngleDistance{T} <: AbstractPosition{T, 3} end

"""
    CartesianPosition{T, N} <: AbstractSatcomCoordinate{T, N}

Abstract type representing a coordinate in `N` dimensions which is backed by
fields all of type `T`. 
Concrete subtypes of this are subtypes of `FieldVector`
"""
abstract type CartesianPosition{T, N} <: AbstractPosition{T, N} end

"""
    LengthCartesian{T, N} <: CartesianPosition{T, N}

Abstract type representing a coordinate in `N` dimensions which is backed by fields all of type `Met{T}`. 
"""
abstract type LengthCartesian{T, N} <: CartesianPosition{T, N} end

"""
    AbstractPointing{T} <: AbstractSatcomCoordinate{T, 3}

Abstract type representing a pointing direction in 3 dimensions which is backed by fields with shared [`numbertype`](@ref) `T`.
"""
abstract type AbstractPointing{T} <: AbstractSatcomCoordinate{T, 3} end

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

abstract type AbstractCRSTransform{T} <: Transform end
abstract type AbstractAffineCRSTransform{T} <: AbstractCRSTransform{T} end
