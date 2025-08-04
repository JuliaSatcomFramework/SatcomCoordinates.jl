"""
    ECI{ID} <: AbstractCRS

This represents an Ellipsoid-Centered Inertial (ECI) CRS which is uniquely identified by its only field `id::ID`.

This is a generalization of the conventianal **ECI** acronym which is only referred to earth-centered coordinates.

The `id` field can be any object that uniquely identifies a specific instance of ECI CRS

When not specified, the default ID for ECEF CRSs is an instance of the singleton type [`EarthDefault`](@ref).

# Conversion between ECEF and ECI

For conversion between coordinates in ECEF and ECI CRSs, the Rotation matrix between the two frames at a specific instane must be provided.
- If that is already available (if it was already computed by other means), this can be directly passed to the [`change_crs`](@ref) function as a keyword argument `R_eci_to_ecef`.
- Alternatively, for custom ECI/ECEF frames, a custom function to compute this rotation matrix based on the IDs of the specific ECI and ECEF frames needs defined as an additional method to the `SatcomCoordinates.eci_to_ecef_rotation` function.
This package only defines a single method of this function where both ECI and ECEF frames are based on the [`EarthDefault`](@ref) frame. Check the docstring of [`SatComCoordinates.eci_to_ecef_rotation`](@ref) for more details.

# Properties/Units/Aliases
- `x` => u"m" => (,): X coordinate in the ECI frame
- `y` => u"m" => (,): Y coordinate in the ECI frame
- `z` => u"m" => (,): Z coordinate in the ECI frame

See also: [`frameid`](@ref), [`ellipsoidparams`](@ref), [`EarthDefault`](@ref), [`ECEF`](@ref), [`eci_to_ecef_rotation`](@ref)
"""
struct ECI{ID} <: AbstractCRS
    id::ID
    # We only have a constructor without parameters specified
    ECI(id) = new{typeof(id)}(id)
end
ECI() = ECI(EarthDefault())
# These are for resolving ambiguities between the default constructor in `coordinates.jl` and the inner one which takes an arbitrary ID
ECI(p::Point{N, Number}) where N = ECI(p...)
ECI(::Number) = _dimension_mismatch_error(ECI(), 1)

frameid(crs::ECI) = return crs.id
