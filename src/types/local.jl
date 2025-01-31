"""
    struct LocalCartesian{T} <: LengthCartesian{T, 3}
Represents a position in a generic local CRS. 

# Fields
- `x::Met{T}`: X-coordinate in meters
- `y::Met{T}`: Y-coordinate in meters
- `z::Met{T}`: Z-coordinate in meters

# Basic Constructors
    LocalCartesian(x::ValidDistance, y::ValidDistance, z::ValidDistance)

`ValidDistance` is either a Real Number, or a subtype of
`Unitful.Length`.

If of the provided argument is `NaN`, the returned `LocalCartesian` object will contain `NaN` for all fields.

# Fallback constructors
All subtypes of `P <: AbstractSatcomCoordinate` can also be constructed using a Tuple or SVector as input, which will be `splatted` into the standard constructor for `P`

See also: [`GeneralizedSpherical`](@ref).
"""
struct LocalCartesian{T} <: LengthCartesian{T, 3}
    x::Met{T}
    y::Met{T}
    z::Met{T}

    BasicTypes.constructor_without_checks(::Type{LocalCartesian{T}}, x, y, z) where T = new{T}(x, y, z)
end


"""
    struct GeneralizedSpherical{T, P <: AbstractPointing{T}} <: AngleAngleDistance{T}
Represents a position in a local CRS, defined by an angular pointing direction and a distance.

# Fields
- `pointing::P`: The pointing direction of the object
- `r::Met{T}`: The distance of the object from the origin of the CRS

The `r` field can also be accessed via `getproperty` using the `distance` alias:

# Basic Constructors
    PointingAndDistance(pointing::P, r::ValidDistance)

`ValidDistance` is either a Real Number, or a subtype of `Unitful.Length`.

If of the provided argument is `NaN`, the returned `PointingAndDistance` object will contain `NaN` for all fields.

See also: [`Spherical`](@ref), [`AzElDistance`](@ref), [`LocalCartesian`](@ref).
"""
struct GeneralizedSpherical{T, P <: AbstractPointing{T}} <: AngleAngleDistance{T}
    pointing::P
    r::Met{T}

    BasicTypes.constructor_without_checks(::Type{GeneralizedSpherical{T, P}}, pointing, r) where {T, P} = new{T, P}(pointing, r)
end
