##### Constructors #####

# ENU/NED
# Handled by generic LengthCartesian constructor in fallbacks.jl

# AER
function AER{T}(az::ValidAngle, el::ValidAngle, r::ValidDistance) where T
    any(isnan, (az, el, r)) && return AER{T}(Val{NaN}())
    az = to_degrees(az, RoundNearest)
    el = to_degrees(el, RoundNearest)
    az, el = wrap_spherical_angles_normalized(az, el, AER)
    r = to_meters(r)
    constructor_without_checks(AER{T}, az, el, r)
end
function AER(az::ValidAngle, el::ValidAngle, r::ValidDistance)
    T = default_numbertype(az, el, r)
    AER{T}(az, el, r)
end

##### Pointing Inversion #####
Base.:(-)(aer::AER) = constructor_without_checks(typeof(aer), aer.az - copysign(180°, aer.az), -aer.el, aer.r)

##### Base.getproperty #####
## ENU
property_aliases(::Type{<:ENU}) = (
    x = (:x, :east),
    y = (:y, :north),
    z = (:z, :up)
)

## NED
property_aliases(::Type{<:NED}) = (
    x = (:x, :north),
    y = (:y, :east),
    z = (:z, :down)
)

## AER
property_aliases(::Type{<:AER}) = (
    az = AZIMUTH_ALIASES,
    el = ELEVATION_ALIASES,
    r = DISTANCE_ALIASES
)

##### Random.rand #####
function Random.rand(rng::AbstractRNG, ::Random.SamplerType{A}) where A <: AER
    az = rand(rng) * 360° - 180°
    el = rand(rng) * 180° - 90°
    r = 1e3 * ((1 + rand(rng)) * u"m")
    constructor_without_checks(enforce_numbertype(A), az, el, r)
end
# ENU/NED
# Handled by generic LengthCartesian function in fallbacks.jl

##### convert #####
## ENU <-> NED
function _convert_different(::Type{T}, src::S) where {T <: Union{ENU, NED}, S <: Union{ENU, NED}}
    C = enforce_numbertype(T, src)
    (;x, y, z) = src
    constructor_without_checks(C, y, x, -z)
end

## ENU/NED <-> AER
function _convert_different(::Type{A}, src::S) where {A <: AER, S <: Union{ENU, NED}}
    C = enforce_numbertype(A, src)
    enu = convert(ENU, src)
    sv = normalized_svector(enu)
    r = norm(sv) * u"m"
    (;az, el) = convert(AzEl, PointingVersor(sv...))
    constructor_without_checks(C, az, el, r)
end
function _convert_different(::Type{S}, src::A) where {S <: Union{ENU, NED}, A <: AER}
    C = enforce_numbertype(S, src)
    T = numbertype(C)
    (; az, el, r) = src
    ae = constructor_without_checks(AzEl{T}, az, el)
    p = convert(PointingVersor, ae)
    (;x, y, z) = normalized_svector(p) .* r
    enu = constructor_without_checks(ENU{T}, x, y, z)
    convert(S, enu)
end

##### Base.isapprox #####
function Base.isapprox(c1::TopocentricPosition, c2::TopocentricPosition; kwargs...)
    e1 = convert(ENU, c1)
    e2 = convert(ENU, c2)
    isapprox(e1, e2; kwargs...)
end
Base.isapprox(c1::ENU, c2::ENU; kwargs...) = isapprox(normalized_svector(c1), normalized_svector(c2); kwargs...)
