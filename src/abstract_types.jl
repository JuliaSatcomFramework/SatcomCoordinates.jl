"""
    FieldVectorCoordinate{N,T} <: FieldVector{N, T}

Abstract type representing a coordinate in `N` dimensions which is backed by
fields all of type `T`. 
Concrete subtypes of this are subtypes of `FieldVector`
from StaticArrays and should likely have to implement `Base.getindex` and
`StaticArraysCore.similar_type`
"""
abstract type FieldVectorCoordinate{N,T} <: FieldVector{N, T} end

abstract type LengthCartesian{N, T} <: FieldVectorCoordinate{N, Met{T}} end
"""
    abstract type NonSVectorCoordinate{N,T} end

Abstract type representing coordinates with `N` dimensions which are not backed by an `SVector`, but should still have the underlying numerical associated to each field be `T`. Example of this is `LLA{T}` which has two fields of type `Deg{T}` and one of type `Met{T}`.
"""
abstract type NonSVectorCoordinate{N,T} end

"""
    AngularPointing{T}

Abstract type representing a pointing direction identified by two angles in
degrees, represented with fields of types `Deg{T}`.
"""
abstract type AngularPointing{T} <: FieldVector{2, Deg{T}} end
