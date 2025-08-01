
"""
    ECEF{ID} <: AbstractCRS

This represents an Ellipsoid-Centered Ellipsoid-Fixed (ECEF) CRS which is uniquely identified by its only field `id::ID`.

This is a generalization of the conventianal **ECEF** acronym which is only referred to earth-centered coordinates.

The `id` field can be any object that uniquely identifies a specific instance of ECEF CRS

When not specified, the default ID for ECEF CRSs is an instance of the singleton type [`EarthDefault`](@ref).

# Properties/Units/Aliases
- `x` => u"m" => (,): X coordinate in the ECEF frame
- `y` => u"m" => (,): Y coordinate in the ECEF frame
- `z` => u"m" => (,): Z coordinate in the ECEF frame

# Constructor
    ECEF(crs)
    ECEF(x, y, z)

See also: [`frameid`](@ref), [`ellipsoidparams`](@ref), [`EarthDefault`](@ref), [`ECI`](@ref), [`LLA`](@ref)

# Extended Help

## Conversion between ECEF and LLA

To allow proper conversion betwen ECEF and LLA, a valid method for:
- `SatcomCoordinates.ellipsoidparams(id::ID)`
must be defined. See the docstrings of [`ellipsoidparams`](@ref) for more details.

Additionally, the conversion is implement inside an extension and relies on the package `SatelliteToolboxTransformations` to be loaded to perform the actual conversion.

## Conversion between ECEF and ECI

For conversion between coordinates in ECEF and ECI CRSs, the Rotation matrix between the two frames at a specific instane must be provided.
- If that is already available (if it was already computed by other means), this can be directly passed to the [`change_crs`](@ref) function as a keyword argument `R_eci_to_ecef`.
- Alternatively, for custom ECI/ECEF frames, a custom function to compute this rotation matrix based on the IDs of the specific ECI and ECEF frames needs defined as an additional method to the `SatcomCoordinates.eci_to_ecef_rotation` function.
This package only defines a single method of this function where both ECI and ECEF frames are based on the [`EarthDefault`](@ref) frame. Check the docstring of [`SatComCoordinates.eci_to_ecef_rotation`](@ref) for more details.
"""
struct ECEF{ID} <: AbstractCRS
    id::ID
    ECEF(id) = new{typeof(id)}(id)
end
ECEF() = ECEF(EarthDefault())
# These are for resolving ambiguities between the default constructor in `coordinates.jl` and the inner one which takes an arbitrary ID
ECEF(p::Point{N, Number}) where N = ECEF(p...)
ECEF(::Number) = _dimension_mismatch_error(ECEF(), 1)

isecefcrs(::Type{<:ECEF}) = true

frameid(crs::ECEF) = return crs.id


#### Random.rand #####
function rand_tuplecoords(rng::AbstractRNG, crs::ECEF, T::Type{<:AbstractFloat})
    # We create a point outside of the ellipsoid surface
    (; a) = ellipsoidparams(crs)
    coeff = T(a)
    dc = rand_tuplecoords(rng, DirectionCosines(), T)
    return dc .* coeff
end