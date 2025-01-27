"""
    CartesianPosition{N,T} <: FieldVector{N, T}

Abstract type representing a coordinate in `N` dimensions which is backed by
fields all of type `T`. 
Concrete subtypes of this are subtypes of `FieldVector`
from StaticArrays.`
"""
abstract type CartesianPosition{N, T} <: FieldVector{N, T} end

abstract type LengthCartesian{N, T} <: CartesianPosition{N, Met{T}} end

"""
    AngularPointing{T}

Abstract type representing a pointing direction identified by two angles in
degrees, represented with fields of types `Deg{T}`.
"""
abstract type AngularPointing{T} end
