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

ellipsoidparams(crs::ECEF) = ellipsoidparams(crs.id)

ellipsoidparams(::Val{:ITRF}) = _ellipsoidparams(6378137.0, 1/298.257223563)