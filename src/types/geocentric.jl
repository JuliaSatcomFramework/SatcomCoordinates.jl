"""
    struct ECEF{T} <: LengthCartesian{T, 3}
Represents a position in the Earth-Centered, Earth-Fixed (ECEF) coordinate system (or generically for other planets, Ellipsoid-Centered, Ellipsoid-Fixed).

# Fields
- `x::Met{T}`: X-coordinate in meters
- `y::Met{T}`: Y-coordinate in meters
- `z::Met{T}`: Z-coordinate in meters

# Basic Constructors
    ECEF(x::ValidDistance, y::ValidDistance, z::ValidDistance)

`ValidDistance` is either a Real Number, or a subtype of
`Unitful.Length`.

If of the provided argument is `NaN`, the returned `ECEF` object will contain `NaN` for all fields.

# Fallback constructors
All subtypes of `P <: AbstractSatcomCoordinate` can also be constructed using a Tuple or SVector as input, which will be `splatted` into the standard constructor for `P`

See also: [`ECI`](@ref), [`LLA`](@ref).
"""
struct ECEF{T} <: LengthCartesian{T, 3}
    x::Met{T}
    y::Met{T}
    z::Met{T}

    BasicTypes.constructor_without_checks(::Type{ECEF{T}}, x, y, z) where T = new{T}(x, y, z)
end

"""
    struct ECI{T} <: LengthCartesian{T, 3}
Represents a position in the Earth-Centered, Inertial (ECI) coordinate system (or generically for other planets, Ellipsoid-Centered, Inertial).

# Fields
- `x::Met{T}`: X-coordinate in meters
- `y::Met{T}`: Y-coordinate in meters
- `z::Met{T}`: Z-coordinate in meters

# Basic Constructors
    ECI(x::ValidDistance, y::ValidDistance, z::ValidDistance)

`ValidDistance` is either a Real Number, or a subtype of
`Unitful.Length`.

If of the provided argument is `NaN`, the returned `ECI` object will contain `NaN` for all fields.

# Fallback constructors
All subtypes of `P <: AbstractSatcomCoordinate` can also be constructed using a Tuple or SVector as input, which will be `splatted` into the standard constructor for `P`

See also: [`ECEF`](@ref), [`LLA`](@ref).
"""
struct ECI{T} <: LengthCartesian{T, 3}
    x::Met{T}
    y::Met{T}
    z::Met{T}

    BasicTypes.constructor_without_checks(::Type{ECI{T}}, x, y, z) where T = new{T}(x, y, z)
end

"""
    struct LLA{T} <: AngleAngleDistance{T}
Identify a point on or above earth using geodetic coordinates

# Fields
- `lat::Deg{T}`: Latitude of the point in degrees [-90°, 90°]
- `lon::Deg{T}`: Longitude of the point in degrees [-180°, 180°]
- `alt::Met{T}`: Altitude of the point above the reference ellipsoid

The fields of `LLA` objects can also be accessed via `getproperty` using the follwing alternative aliases:
- `latitude` for `lat`
- `longitude` for `lon`
- `altitude`, `h` or `height` for `alt`

# Basic Constructors
    LLA(lat::ValidAngle,lon::ValidAngle,alt::ValidDistance)
    LLA(lat::ValidAngle,lon::ValidAngle) # Defaults to 0m altitude

`ValidAngle` is a either a Real number or a `Unitful.Quantity` of unit either
`u"rad"` or `u"°"`.

`ValidDistance` is either a Real Number, or a subtype of
`Unitful.Length`.

If of the provided argument is `NaN`, the returned `LLA` object will contain `NaN` for all fields.

# Fallback constructors
All subtypes of `P <: AbstractSatcomCoordinate` can also be constructed using a Tuple or SVector as input, which will be `splatted` into the standard constructor for `P`

See also: [`ECEF`](@ref), [`ECI`](@ref).
"""
struct LLA{T} <: AngleAngleDistance{T}
    lat::Deg{T}
    lon::Deg{T}
    alt::Met{T}

    BasicTypes.constructor_without_checks(::Type{LLA{T}}, lat, lon, alt) where T = new{T}(lat, lon, alt)
end
