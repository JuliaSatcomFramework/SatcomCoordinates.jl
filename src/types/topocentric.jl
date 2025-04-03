"""
    struct ENU{T} <: AbstractTopocentricPosition{T}
Represents a position in the East-North-Up (ENU) coordinate system, which is a local coordinate system centered at a point on or above the surface of an Ellipsoid. 
The direction of the ENU axes is uniquely determined by the latitude, longitude, and altitude of the point w.r.t. the referenced ellipsoid.

# Properties
- `x::Met{T}`: X-coordinate in meters
- `y::Met{T}`: Y-coordinate in meters
- `z::Met{T}`: Z-coordinate in meters

# Basic Constructors
    ENU(x::ValidDistance, y::ValidDistance, z::ValidDistance)

`ValidDistance` is either a Real Number, or a subtype of
`Unitful.Length`.

If of the provided argument is `NaN`, the returned `ENU` object will contain `NaN` for all fields.

# Fallback constructors
All subtypes of `P <: AbstractSatcomCoordinate` can also be constructed using a Tuple or SVector as input, which will be `splatted` into the standard constructor for `P`

See also: [`NED`](@ref), [`AER`](@ref).
"""
struct ENU{T} <: AbstractTopocentricPosition{T}
    svector::SVector{3, T}

    BasicTypes.constructor_without_checks(::Type{ENU{T}}, sv::SVector{3, T}) where T = new{T}(sv)
end

"""
    struct NED{T} <: AbstractTopocentricPosition{T}
Represents a position in the North-East-Down (NED) coordinate system, which is a local coordinate system centered at a point on or above the surface of an Ellipsoid. 
The direction of the NED axes is uniquely determined by the latitude, longitude, and altitude of the point w.r.t. the referenced ellipsoid.

# Properties
- `x::Met{T}`: X-coordinate in meters
- `y::Met{T}`: Y-coordinate in meters
- `z::Met{T}`: Z-coordinate in meters

# Basic Constructors
    NED(x::ValidDistance, y::ValidDistance, z::ValidDistance)

`ValidDistance` is either a Real Number, or a subtype of
`Unitful.Length`.

If of the provided argument is `NaN`, the returned `NED` object will contain `NaN` for all fields.

# Fallback constructors
All subtypes of `P <: AbstractSatcomCoordinate` can also be constructed using a Tuple or SVector as input, which will be `splatted` into the standard constructor for `P`

See also: [`ENU`](@ref), [`AER`](@ref).
"""
struct NED{T} <: AbstractTopocentricPosition{T}
    svector::SVector{3, T}
    BasicTypes.constructor_without_checks(::Type{NED{T}}, sv::SVector{3, T}) where T = new{T}(sv)
end

"""
    struct AER{T} <: AbstractTopocentricPosition{T}
Represents a position in the Azimuth-Elevation-Range (AER) coordinate system, which is a local coordinate system centered at a point on or above the surface of an Ellipsoid. 
The Elevation and Azimuth angles are always defined w.r.t. the ENU CRS with the same origin. More specifically:

# Properties
- `az::Deg{T}`: Azimuth angle, defined angle in the XY (North-East) plane from the +Y (North) direction to the object, positive towards +X (East) direction. It is constrained to be in the range `[-180°, 180°]`
- `el::Deg{T}`: Elevation angle, defined as the angle between the XY plane and the point being described by the AER coordinates, positive towards +Z (Up) direction. It is constrained to be in the range `[-90°, 90°]`
- `r::Met{T}`: Range in meters between the origin of the ENU CRS and the point being described by the AER coordinates.

# Basic Constructors
    AER(az::ValidAngle, el::ValidAngle, r::ValidDistance)

`ValidAngle` is either a Real Number, or a subtype of `Unitful.Angle`.
`ValidDistance` is either a Real Number, or a subtype of `Unitful.Length`.

If of the provided argument is `NaN`, the returned `AER` object will contain `NaN` for all fields.

# Fallback constructors
All subtypes of `P <: AbstractSatcomCoordinate` can also be constructed using a Tuple or SVector as input, which will be `splatted` into the standard constructor for `P`

See also: [`ENU`](@ref), [`NED`](@ref).
"""
struct AER{T} <: AbstractTopocentricPosition{T}
    svector::SVector{3, T}
    BasicTypes.constructor_without_checks(::Type{AER{T}}, sv::SVector{3, T}) where T = new{T}(sv)
end