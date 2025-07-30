"""
    DefaultEarthFrame

This represents the default frame ID representing the Earth for both the ECEF and ECI CRSs

It assumes the WGS84 ellipsoid and assumes that the frames from conversion between ECEF and ECI are the following:
- ECEF: ITRF
- ECI: GCRS 

See also: [`ellipsoidparams`](@ref), [`ECEF`](@ref), [`ECI`](@ref)
"""
struct DefaultEarthFrame end

ellipsoidparams(::DefaultEarthFrame) = WGS84_PARAMS

"""
    ECEF{ID} <: AbstractCRS

This represents an Ellipsoid-Centered Ellipsoid-Fixed (ECEF) CRS which is uniquely identified by its only field `id::ID`.

This is a generalization of the conventianal **ECEF** acronym which is only referred to earth-centered coordinates.

The `id` field can be any object that uniquely identifies a specific instance of ECEF CRS

To allow proper conversion betwen ECEF and LLA, a valid method for:
- `SatcomCoordinates.ellipsoidparams(id::ID)`
must be defined. See the docstrings of [`ellipsoidparams`](@ref) for more details.

For conversion between coordinates in ECEF and ECI CRSs, the following method must also be implemented:
- `SatcomCoordinates.eci_to_ecef_rotation(eci_id::ID1, ecef_id::ID2; kwargs...)`
See its docstring for more details

When not specified, the default ID for ECEF CRSs is an instance of the singleton type [`DefaultEarthFrame`](@ref).

See also: [`ecefid`](@ref), [`ellipsoidparams`](@ref), [`DefaultEarthFrame`](@ref)
"""
struct ECEF{ID} <: AbstractCRS
    id::ID
    ECEF(id) = new{typeof(id)}(id)
end
ECEF() = ECEF(DefaultEarthFrame())

"""
    frameid(crs::AbstractCRS)

Extracts the frame identifier associated to the CRS `crs`. This is currently only used to extract the `id` field from the ECI and ECEF CRSs for further processing (e.g. extracting the ellipsoid parameters associated to the frame id)

"""
frameid(crs::ECEF) = return crs.id
function frameid(crs::AbstractCRS)
    base = basecrs(crs)
    linked = linkedcrs(crs)
    if base === linked === base
        # We are dealing with a root CRS, and these must explicitly create a custom method for `frameid` if they have one
        throw(ArgumentError("The provided CRS does not seem to contain a frame id. Currently only `ECEF` and `ECI` frames support that."))
    elseif base !== crs
        # We try to go over the base CRS
        return frameid(base)
    else
        # We are dealing with a simple derived CRS, so we try to go over the linked CRS
        return frameid(linked)
    end
end
frameid(coord::AbstractSatcomCoordinate) = frameid(crs(coord))

function _ellipsoidparams(semimajor::Real, flattening::Real)
    @inline
    a, f = promote_valuetype(AbstractFloat, Float64, semimajor, flattening)
    b = a * (1 - f)
    e² = f * (2 - f)
    el² = e² / (1 - e²)
    nt = (; a, f, b, e², el²)
    return nt
end

# Ellipsoid parameters of the WGS84 ellipsoid
const WGS84_PARAMS = _ellipsoidparams(6378137.0, 1/298.257223563)
# Ellipsoid parameters of the GRS80 ellipsoid
const GRS80_PARAMS = _ellipsoidparams(6378137.0, 1/298.257222101)

"""
    ellipsoidparams(frame_id)

Function that shall have a valid method for all valid `id` (of either ECEF or ECI CRS) instances and shall return a NamedTuple with the following fields representing the useful ellipsoid parameters:
- `a`: Semimajor axis
- `f`: Flattening
- `b`: Semiminor axis
- `e²`: First eccentricity squared
- `el²`: Second eccentricity squared

# Example
Calling this function on the default Earth frames provides the output for the WGS84 ellipsoid:
```jldoctest
julia> using SatcomCoordinates: ellipsoidparams, DefaultEarthFrame

julia> ellipsoidparams(DefaultEarthFrame())
(a = 6.378137e6, f = 0.0033528106647474805, b = 6.356752314245179e6, e² = 0.0066943799901413165, el² = 0.006739496742276434)
```
"""
ellipsoidparams(crs::AbstractCRS) = ellipsoidparams(frameid(crs))

#### Random.rand #####
function rand_tuplecoords(rng::AbstractRNG, crs::ECEF, T::Type{<:AbstractFloat})
    # We create a point outside of the ellipsoid surface
    (; a) = ellipsoidparams(crs)
    coeff = T(a)
    dc = rand_tuplecoords(rng, DirectionCosines(), T)
    return dc .* coeff
end