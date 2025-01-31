##### Constructors #####

# ENU/NED
# Handled by generic LengthCartesian constructor in fallbacks.jl

# AER
function AER{T}(az::ValidAngle, el::ValidAngle, r::ValidDistance) where T
    any(isnan, (az, el, r)) && return constructor_without_checks(AER{T}, NaN * u"°", NaN * u"°", NaN * u"m")
    az = to_degrees(az, RoundNearest)
    el = to_degrees(el, RoundNearest)
    az, el = wrap_spherical_angles_normalized(az, el, AER)
    r = to_meters(r)
    constructor_without_checks(AER{T}, az, el, r)
end
function AER(az::ValidAngle, el::ValidAngle, r::ValidDistance)
    NT = promote_type(map(numbertype, (az, el, r))...)
    T = NT <: AbstractFloat ? NT : Float64
    AER{T}(az, el, r)
end

##### Base.getproperty #####
## ENU
function Base.getproperty(enu::ENU, s::Symbol) 
    s in (:x, :east) && return getfield(enu, :x)
    s in (:y, :north) && return getfield(enu, :y)
    s in (:z, :up) && return getfield(enu, :z)
    throw(ArgumentError("Objects of type `ENU` do not have a property called $s"))
end

## NED
function Base.getproperty(ned::NED, s::Symbol) 
    s in (:x, :north) && return getfield(ned, :x)
    s in (:y, :east) && return getfield(ned, :y)
    s in (:z, :down) && return getfield(ned, :z)
    throw(ArgumentError("Objects of type `NED` do not have a property called $s"))
end

## AER
function Base.getproperty(aer::AER, s::Symbol) 
    s in (:az, :azimuth) && return getfield(aer, :az)
    s in (:el, :elevation) && return getfield(aer, :el)
    s in (:r, :range, :distance) && return getfield(aer, :r)
    throw(ArgumentError("Objects of type `AER` do not have a property called $s"))
end

##### Random.rand #####
function Random.rand(rng::AbstractRNG, ::Random.SamplerType{A}) where A <: AER
    az = rand(rng) * 360° - 180°
    el = rand(rng) * 180° - 90°
    r = 1e3 * ((1 + rand(rng)) * u"m")
    constructor_without_checks(enforce_numbertype(A), az, el, r)
end

function Random.rand(rng::AbstractRNG, ::Random.SamplerType{E}) where E <: Union{ENU, NED}
    C = enforce_numbertype(E)
    T = numbertype(C)
    p = rand(rng, PointingVersor{T}) |> to_svector
    x, y, z = p * (1e3 * ((1 + rand(rng)) * u"m"))
    constructor_without_checks(C, x, y, z)
end

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
    sv = to_svector(enu)
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
    (;x, y, z) = to_svector(p) .* r
    enu = constructor_without_checks(ENU{T}, x, y, z)
    convert(S, enu)
end

##### Base.isapprox #####
function Base.isapprox(c1::TopocentricPosition, c2::TopocentricPosition; kwargs...)
    e1 = convert(ENU, c1)
    e2 = convert(ENU, c2)
    isapprox(e1, e2; kwargs...)
end
Base.isapprox(c1::ENU, c2::ENU; kwargs...) = isapprox(to_svector(c1), to_svector(c2); kwargs...)
