"""
    struct ENU{T} <: LengthCartesian{T, 3}
Represents a position in the East-North-Up (ENU) coordinate system, which is a local coordinate system centered at a point on or above the surface of an Ellipsoid. 
The direction of the ENU axes is uniquely determined by the latitude, longitude, and altitude of the point w.r.t. the referenced ellipsoid.

# Fields
- `x::Met{T}`: X-coordinate in meters
- `y::Met{T}`: Y-coordinate in meters
- `z::Met{T}`: Z-coordinate in meters

The fields of `ENU` objects can also be accessed via `getproperty` using the follwing alternative aliases:
- `east` for `x`
- `north` for `y`
- `up` for `z`

# Basic Constructors
    ENU(x::ValidDistance, y::ValidDistance, z::ValidDistance)

`ValidDistance` is either a Real Number, or a subtype of
`Unitful.Length`.

If of the provided argument is `NaN`, the returned `ENU` object will contain `NaN` for all fields.

# Fallback constructors
All subtypes of `P <: AbstractSatcomCoordinate` can also be constructed using a Tuple or SVector as input, which will be `splatted` into the standard constructor for `P`

See also: [`NED`](@ref), [`AER`](@ref).
"""
struct ENU{T} <: LengthCartesian{T, 3}
    x::Met{T}
    y::Met{T}
    z::Met{T}

    BasicTypes.constructor_without_checks(::Type{ENU{T}}, x, y, z) where T = new{T}(x, y, z)
end

"""
    struct NED{T} <: LengthCartesian{T, 3}
Represents a position in the North-East-Down (NED) coordinate system, which is a local coordinate system centered at a point on or above the surface of an Ellipsoid. 
The direction of the NED axes is uniquely determined by the latitude, longitude, and altitude of the point w.r.t. the referenced ellipsoid.

# Fields
- `x::Met{T}`: X-coordinate in meters
- `y::Met{T}`: Y-coordinate in meters
- `z::Met{T}`: Z-coordinate in meters

The fields of `NED` objects can also be accessed via `getproperty` using the follwing alternative aliases:
- `north` for `x`
- `east` for `y`
- `down` for `z`

# Basic Constructors
    NED(x::ValidDistance, y::ValidDistance, z::ValidDistance)

`ValidDistance` is either a Real Number, or a subtype of
`Unitful.Length`.

If of the provided argument is `NaN`, the returned `NED` object will contain `NaN` for all fields.

# Fallback constructors
All subtypes of `P <: AbstractSatcomCoordinate` can also be constructed using a Tuple or SVector as input, which will be `splatted` into the standard constructor for `P`

See also: [`ENU`](@ref), [`AER`](@ref).
"""
struct NED{T} <: LengthCartesian{T, 3}
    x::Met{T}
    y::Met{T}
    z::Met{T}
    BasicTypes.constructor_without_checks(::Type{NED{T}}, x, y, z) where T = new{T}(x, y, z)
end

"""
    struct AER{T} <: AngleAngleDistance{T}
Represents a position in the Azimuth-Elevation-Range (AER) coordinate system, which is a local coordinate system centered at a point on or above the surface of an Ellipsoid. 
The Elevation and Azimuth angles are always defined w.r.t. the ENU CRS with the same origin. More specifically:

# Fields
- `az::Deg{T}`: Azimuth angle, defined angle in the XY (North-East) plane from the +Y (North) direction to the object, positive towards +X (East) direction. It is constrained to be in the range `[-180°, 180°]`
- `el::Deg{T}`: Elevation angle, defined as the angle between the XY plane and the point being described by the AER coordinates, positive towards +Z (Up) direction. It is constrained to be in the range `[-90°, 90°]`
- `r::Met{T}`: Range in meters between the origin of the ENU CRS and the point being described by the AER coordinates.
"""
struct AER{T} <: AngleAngleDistance{T}
    az::Deg{T}
    el::Deg{T}
    r::Met{T}
    BasicTypes.constructor_without_checks(::Type{AER{T}}, az, el, r) where T = new{T}(az, el, r)
end

const TopocentricPosition{T} = Union{ENU{T}, NED{T}, AER{T}}
