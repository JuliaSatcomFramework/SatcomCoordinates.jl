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
    function ECEF(id)
        if id isa Symbol
            id = Val(id)
        end
        new{typeof(id)}(id)
    end
end
ECEF() = ECEF(DefaultEarthFrame())

"""
    ecefid(crs::ECEF)

    Extracts the ECEF identifier from an ECEF CRS
"""
ecefid(crs::ECEF) = return crs.id
ecefid(crs::AbstractLinkedCRS{<:ECEF}) = return ecefid(linkedcrs(crs))
function ecefid(crs::AbstractCRS)
    base = basecrs(crs)
    base === crs && throw(ArgumentError("The provided CRS is not an ECEF CRS, so it cannot be used to extract the ECEF identifier."))
    return ecefid(base)
end

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
    ellipsoidparams(ecef_id)

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
ellipsoidparams(crs::ECEF) = ellipsoidparams(ecefid(crs))

#### Random.rand #####
function rand_tuplecoords(rng::AbstractRNG, crs::ECEF, T::Type{<:AbstractFloat})
    # We create a point outside of the ellipsoid surface
    (; a) = ellipsoidparams(crs)
    coeff = T(a)
    dc = rand_tuplecoords(rng, DirectionCosines(), T)
    return dc .* coeff
end