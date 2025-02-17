### Geocentric
"""
    const GeocentricPosition{T} = Union{ECEF{T}, ECI{T}, LLA{T}}

Union of all types that can represent a position in the geocentric coordinate system.
"""
const GeocentricPosition{T} = Union{ECEF{T}, ECI{T}, LLA{T}}

### Topocentric
"""
    const TopocentricPosition{T} = Union{ENU{T}, NED{T}, AER{T}}

Union of all types that can represent a position in a topocentric coordinate system.
"""
const TopocentricPosition{T} = Union{ENU{T}, NED{T}, AER{T}}

### Generic Local
"""
    const Spherical{T} = GeneralizedSpherical{T, ThetaPhi{T}}

Type representing a position in ISO/Physics spherical coordinates
"""
const Spherical{T} = GeneralizedSpherical{T, ThetaPhi{T}}

"""
    const AzElDistance{T} = GeneralizedSpherical{T, AzEl{T}}

Type representing a position w.r.t. a local CRS in Azimuth, Elevation and Range coordinates.
The difference between `AzElDistance` and [`AER`](@ref) is that `AER` is a always referred to the ENU CRS, while `AzElDistance` is for a generic local CRS.
"""
const AzElDistance{T} = GeneralizedSpherical{T, AzEl{T}}

"""
    const GenericLocalPosition{T} = Union{LocalCartesian{T}, GeneralizedSpherical{T}}

Union of all types that can represent a position in a generic local coordinate system.
"""
const GenericLocalPosition{T} = Union{LocalCartesian{T}, GeneralizedSpherical{T}}


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

# These are const variables used to overload getproperty for specific fields
const THETA_ALIASES = (:θ, :theta, :t)
const PHI_ALIASES = (:φ, :ϕ, :phi, :p)
const AZIMUTH_ALIASES = (:az, :azimuth)
const ELEVATION_ALIASES = (:el, :elevation)
const DISTANCE_ALIASES = (:r, :distance, :range)