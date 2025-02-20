"""
    struct LocalCartesian{T} <: AbstractLocalPosition{T, 3}
Represents a position in a generic local CRS. 

# Properties
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
struct LocalCartesian{T} <: AbstractLocalPosition{T, 3}
    svector::SVector{3, T}

    BasicTypes.constructor_without_checks(::Type{LocalCartesian{T}}, svector::SVector{3, T}) where T = new{T}(svector)
end


"""
    struct GeneralizedSpherical{T, P <: AngularPointing} <: AbstractPosition{T, 3}
Represents a position in a local CRS, defined by an angular pointing direction and a distance.

!!! note
    The parameter `P` should not be a concrete type of angular pointing but a basic subtype without the `numbertype` parameter, e.g. `AzEl` instead of `AzEl{Float64}`.

# Properties
- `angle1::Deg{T}`: First angle of the referenced angular pointing CRS `P`. The name of the property is actually not `angle1` but will be the first property of objects of type `P`
- `angle2::Deg{T}`: Second angle of the referenced angular pointing CRS `P`. The name of the property is actually not `angle2` but will be the second property of objects of type `P`
- `r::Met{T}`: The distance of the object from the origin of the CRS

# Basic Constructors
    PointingAndDistance(pointing::AngularPointing, r::ValidDistance)

`ValidDistance` is either a Real Number, or a subtype of `Unitful.Length`.

If of the provided argument is `NaN`, the returned `PointingAndDistance` object will contain `NaN` for all fields.

See also: [`Spherical`](@ref), [`AzElDistance`](@ref), [`LocalCartesian`](@ref).
"""
struct GeneralizedSpherical{P <: AngularPointing, T} <: AbstractLocalPosition{T, 3}
    svector::SVector{3, T}

    BasicTypes.constructor_without_checks(::Type{GeneralizedSpherical{P, T}}, svector::SVector{3, T}) where {T, P} = new{P, T}(svector)
end