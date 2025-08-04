"""
    frameid(crs::AbstractCRS)

Extracts the frame identifier associated to the CRS `crs`. This is currently only used to extract the `id` field from the ECI and ECEF CRSs for further processing (e.g. extracting the ellipsoid parameters associated to the frame id)

See also: [`ellipsoidparams`](@ref), [`EarthDefault`](@ref)
"""
function frameid(crs::AbstractCRS)
    base = basecrs(crs)
    linked = linkedcrs(crs)
    if base === linked === crs
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
julia> using SatcomCoordinates: ellipsoidparams, EarthDefault

julia> ellipsoidparams(EarthDefault())
(a = 6.378137e6, f = 0.0033528106647474805, b = 6.356752314245179e6, e² = 0.0066943799901413165, el² = 0.006739496742276434)
```
"""
ellipsoidparams(crs::AbstractCRS) = ellipsoidparams(frameid(crs))

"""
    EarthDefault

This represents the default frame ID representing the Earth for both the ECEF and ECI CRSs

It assumes the WGS84 ellipsoid and assumes that the frames from conversion between ECEF and ECI are the following:
- ECEF: ITRF
- ECI: GCRS 

See also: [`ellipsoidparams`](@ref), [`ECEF`](@ref), [`ECI`](@ref)
"""
struct EarthDefault end

ellipsoidparams(::EarthDefault) = WGS84_PARAMS