position_trait(::Type{<:AER}) = SphericalPositionTrait()

##### Constructors #####

# ENU/NED
# Handled by generic LengthCartesian constructor in fallbacks.jl

# AER
function construct_inner_svector(::Type{AER{T}}, az::ValidAngle, el::ValidAngle, r::ValidDistance) where T
    az = to_degrees(az, RoundNearest)
    el = to_degrees(el, RoundNearest)
    az, el = wrap_spherical_angles_normalized(az, el, AER)
    az = stripdeg(az)
    el = stripdeg(el)
    r = to_meters(r) |> ustrip
    SVector{3, T}(az, el, r)
end

##### Pointing Inversion #####
function Base.:(-)(aer::AER) 
    AE = typeof(aer)
    T = numbertype(AE)
    az, el, r = raw_svector(aer)
    az = az - copysign(π, az)
    el = -el
    constructor_without_checks(AE, SVector{3, T}(az, el, r))
end

##### Base.getproperty #####
## ENU/NED covered by position fallback

## AER
properties_names(::Type{<:AER}) = (:az, :el, :r)

##### Random.rand #####
function Random.rand(rng::AbstractRNG, ::Random.SamplerType{A}) where A <: AER
    AE = enforce_numbertype(A)
    T = numbertype(AE)
    az = rand(rng) * π - π/2
    el = rand(rng) * π/2 - π/4
    r = 1e3 * (1 + rand(rng))
    constructor_without_checks(AE, SVector{3, T}(az, el, r))
end
# ENU/NED
# Handled by generic LengthCartesian function in fallbacks.jl

##### convert #####
## ENU <-> NED
function _convert_different(CRSₒ::Type{<:Union{ENU, NED}}, src::Union{ENU, NED})
    C = enforce_numbertype(CRSₒ, src)
    T = numbertype(C)
    x, y, z = raw_svector(src)
    constructor_without_checks(C, SVector{3, T}(y, x, -z))
end

## ENU/NED <-> AER
function _convert_different(A::Type{<:AER}, src::Union{ENU, NED})
    C = enforce_numbertype(A, src)
    T = numbertype(C)
    enu = convert(ENU, src)
    sv = raw_svector(enu)
    r = norm(sv)
    p = constructor_without_checks(PointingVersor{T}, sv ./ r)
    (;az, el) = convert(AzEl, p) |> raw_properties
    constructor_without_checks(C, SVector{3, T}(az, el, r))
end
function _convert_different(S::Type{<:Union{ENU, NED}}, src::AER)
    C = enforce_numbertype(S, src)
    T = numbertype(C)
    (; az, el, r) = raw_properties(src)
    ae = constructor_without_checks(AzEl{T}, SVector{2, T}(az, el))
    p = convert(PointingVersor, ae)
    sv = raw_svector(p) * r
    enu = constructor_without_checks(ENU{T}, sv)
    convert(S, enu)
end

##### Base.isapprox #####
function Base.isapprox(c1::AbstractTopocentricPosition, c2::AbstractTopocentricPosition; kwargs...)
    e1 = convert(ENU, c1)
    e2 = convert(ENU, c2)
    isapprox(e1, e2; kwargs...)
end
Base.isapprox(c1::ENU, c2::ENU; kwargs...) = isapprox(raw_svector(c1), raw_svector(c2); kwargs...)
