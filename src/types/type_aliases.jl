### Generic Local
"""
    const Spherical{T} = GeneralizedSpherical{ThetaPhi, T}

Type representing a position in ISO/Physics spherical coordinates
"""
const Spherical{T} = GeneralizedSpherical{ThetaPhi, T}

"""
    const AzElDistance{T} = GeneralizedSpherical{AzEl, T}

Type representing a position w.r.t. a local CRS in Azimuth, Elevation and Range coordinates.
The difference between `AzElDistance` and [`AER`](@ref) is that `AER` is a always referred to the ENU CRS, while `AzElDistance` is for a generic local CRS.
"""
const AzElDistance{T} = GeneralizedSpherical{AzEl, T}
"""
    const ForwardOrInverse{F <: AbstractCRSTransform} = Union{F, InverseTransform{<:Any, <:F}}

Union representing either a forward or reverse transform of F
"""
const ForwardOrInverse{F <: AbstractCRSTransform} = Union{F, InverseTransform{<:Any, <:F}}

"""
    const WithNumbertype{T} = Union{AbstractSatcomCoordinate{T}, AbstractCRSTransform{T}}

Union representing the types defined and exported by this package, which always have a numbertype as first parameter.
"""
const WithNumbertype{T} = Union{AbstractSatcomCoordinate{T}, AbstractCRSTransform{T}}