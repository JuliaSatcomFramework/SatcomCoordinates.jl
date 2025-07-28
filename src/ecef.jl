struct ECEF{ID} <: AbstractCRS
    id::ID
    function ECEF(id)
        if id isa Symbol
            id = Val(id)
        end
        new{typeof(id)}(id)
    end
end
ECEF() = ECEF(:ITRF)

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

Function that shall have a valid method for all valid `id` and shall return a NamedTuple with the following fields representing the useful ellipsoid parameters:
- `a`: Semimajor axis
- `f`: Flattening
- `b`: Semiminor axis
- `e²`: First eccentricity squared
- `el²`: Second eccentricity squared
"""
ellipsoidparams(crs::ECEF) = ellipsoidparams(crs.id)

ellipsoidparams(::Val{:ITRF}) = GRS80_PARAMS


#### Random.rand #####
function rand_tuplecoords(rng::AbstractRNG, crs::ECEF, T::Type{<:AbstractFloat})
    # We create a point outside of the ellipsoid surface
    (; a) = ellipsoidparams(crs)
    coeff = T(a)
    dc = rand_tuplecoords(rng, DirectionCosines(), T)
    return dc .* coeff
end