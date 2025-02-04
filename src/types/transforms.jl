"""
    InverseTransform{T, F <: AbstractCRSTransform{T}} <: AbstractCRSTransform{T}

A type representing an inverse of an [`AbstractCRSTransform`](@ref).
"""
struct InverseTransform{T, F <: AbstractCRSTransform{T}} <: AbstractCRSTransform{T}
    transform::F
end

abstract type AbstractCRSRotation{T} <: AbstractCRSTransform{T} end

"""
    CRSRotation{T, R <: StaticMatrix{T, 3, 3}} <: AbstractCRSRotation{T}

A type representing a basic rotation of a coordinate system.
"""
struct CRSRotation{T, R <: Rotation{3, T}} <: AbstractCRSRotation{T}
    rotation::R
end

"""
    BasicCRSTransform{T, R <: Union{CRSRotation{T}, Identity}, O <: CartesianPosition{T}} <: AbstractCRSTransform{T}

A type representing a basic transformation (rotation + translation).

# Fields:
- `rotation::R`: The rotation of the transformation.
- `origin::O`: The origin of the transformation.
"""
struct BasicCRSTransform{T, R <: Union{CRSRotation{T}, Identity}, O <: CartesianPosition{T}} <: AbstractAffineCRSTransform{T}
    rotation::R
    origin::O
end