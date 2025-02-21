##### Constructors #####
function (P::Type{<:AbstractPointing})(args::Vararg{ValidAngle, 2})
    PT = enforce_numbertype(P, default_numbertype(args...))
    any(isnan, args) && return PT(Val{NaN}())
    v = construct_inner_svector(PT, args...)
    return constructor_without_checks(PT, v)
end
(P::Type{<:AbstractPointing})(coords::Point{2, ValidAngle}) = P(coords...)

# Pointing Versor
function construct_inner_svector(::Type{PointingVersor{T}}, x, y, z) where T <: AbstractFloat
    return SVector{3, T}(x, y, z) |> normalize
end
function (P::Type{<:PointingVersor})(args::Vararg{ValidAngle, 3})
    PT = enforce_numbertype(P, default_numbertype(args...))
    any(isnan, args) && return PT(Val{NaN}())
    v = construct_inner_svector(PT, args...)
    return constructor_without_checks(PT, v)
end
(P::Type{<:PointingVersor})(coords::Point{3, ValidAngle}) = P(coords...)


# UV
const UV_CONSTRUCTOR_TOLERANCE = Ref{Float64}(1e-5)

function construct_inner_svector(::Type{UV{T}}, u, v) where T <: AbstractFloat 
    n = u^2 + v^2
    tol = UV_CONSTRUCTOR_TOLERANCE[]
    lim = 1 + tol
    if (n > 1 && n <= lim)
        c = 1 / sqrt(n)
        u *= c
        v *= c
    end
    if (n > lim) 
        error("The provided inputs do not satisfy u^2 + v^2 <= 1 + tolerance
    u = $u 
    v = $v 
    u^2 + v^2 = $n
    tolerance = $(tol)")
    end
    return SVector{2, T}(u, v)
end


# AngularPointing
function construct_inner_svector(::Type{P}, α, β) where{T <: AbstractFloat, P <: Union{AzOverEl{T}, ElOverAz{T}, ThetaPhi{T}, AzEl{T}}}
    any(isnan, (α, β)) && return P(Val{NaN}())
    α = to_degrees(α, RoundNearest)
    β = to_degrees(β, RoundNearest)
    α, β = wrap_spherical_angles_normalized(α, β, P)
    α, β = map(stripdeg, (α, β))
    return SVector{2, T}(α, β)
end

# Constructors without numbertype, and with tuple or SVector as input
# for P in (:UV, :ThetaPhi, :AzEl, :AzOverEl, :ElOverAz, :PointingVersor)
#     NT = P in (:UV, :PointingVersor) ? :Real : :ValidAngle
#     N = P === :PointingVersor ? 3 : 2
#     eval(:(
#     function $P(vals::Vararg{$NT, $N})
#         T = default_numbertype(vals...)
#         $P{T}(vals...)
#     end
#     ))
# end

# Properties
properties_names(::Type{<:PointingVersor}) = (:x, :y, :z)
properties_names(::Type{<:Union{AzOverEl, ElOverAz, AzEl}}) = (:az, :el)
properties_names(::Type{<:ThetaPhi}) = (:θ, :φ)
properties_names(::Type{<:UV}) = (:u, :v)

ConstructionBase.getproperties(p::AngularPointing) = map(asdeg, raw_properties(p))

##### Pointing Inversion #####
# We define the -p operation for pointing directions as the pointing direction which is in the opposite direction of p on the unitary sphere.

Base.:(-)(p::P) where P <: PointingVersor = constructor_without_checks(P, -raw_svector(p))
function Base.:(-)(p::Union{ElOverAz, AzEl, AzOverEl})
    AP = typeof(p)
    T = numbertype(AP)
    (;az, el) = raw_properties(p)
    if p isa Union{AzEl, ElOverAz}
        el = -el
    end
    az = az - copysign(π, az)
    constructor_without_checks(AP, SVector{2, T}(az, el))
end
function Base.:(-)(p::ThetaPhi)
    TP = typeof(p)
    T = numbertype(TP)
    (;θ, φ) = raw_properties(p)
    v = SVector{2, T}(π - θ, φ - copysign(π, φ))
    constructor_without_checks(TP, v)
end

##### Conversions #####
# UV <-> PointingVersor
function _convert_different(::Type{P}, uv::UV) where {P <: PointingVersor}  
    PT = enforce_numbertype(P, uv)
    T = numbertype(PT)
    (;u,v) = raw_properties(uv)
    w = sqrt(1 - u^2 - v^2)
    v = SVector{3, T}(u, v, w)
    constructor_without_checks(PT, v)
end
function _convert_different(::Type{U}, pv::PointingVersor) where U <: UV 
    @assert pv.z >= 0 "The provided PointingVersor is located in the half-hemisphere containing the cartesian -Z axis and can not be converted to UV coordinates"
    UT = enforce_numbertype(U, pv)
    T = numbertype(UT)
    (;x, y) = raw_properties(pv)
    constructor_without_checks(UT, SVector{2, T}(x, y))
end

# ThetaPhi <-> UV (Specific implementation for slightly faster conversion)
function _convert_different(::Type{U}, tp::ThetaPhi) where U <: UV
	(;θ,φ) = raw_properties(tp)
	@assert θ <= π/2 "The provided ThetaPhi pointing $tp has θ > 90° so it lies in the half-hemisphere containing the -Z axis and can not be represented in UV"
	v, u = sin(θ) .* sincos(φ)
    UT = enforce_numbertype(U, tp)
    T = numbertype(UT)
    constructor_without_checks(UT, SVector{2, T}(u, v))
end
function _convert_different(::Type{TP}, uv::UV) where TP <: ThetaPhi
	(;u,v) = raw_properties(uv)
    TPT = enforce_numbertype(TP, uv)
    T = numbertype(TPT)
	θ = asin(sqrt(u^2 + v^2))
	φ = atan(v,u)
    v = SVector{2, T}(θ, φ)
	return constructor_without_checks(TPT, v)
end

# ThetaPhi <-> PointingVersor
function _convert_different(::Type{P}, tp::ThetaPhi) where P <: PointingVersor
	(; θ, φ) = raw_properties(tp)
    PT = enforce_numbertype(P, tp)
    T = numbertype(PT)
	sθ,cθ = sincos(θ)
	sφ,cφ = sincos(φ)
	x = sθ * cφ
	y = sθ * sφ 
	z = cθ
    v = SVector{3, T}(x, y, z)
    constructor_without_checks(PT, v)
end
function _convert_different(::Type{TP}, pv::PointingVersor) where TP <: ThetaPhi
	(;x,y,z) = raw_properties(pv)
    TPT = enforce_numbertype(TP, pv)
    T = numbertype(TPT)
	θ = acos(z)
	φ = atan(y,x)
    v = SVector{2, T}(θ, φ)
    constructor_without_checks(TPT, v)
end

# ThetaPhi <-> AzEl
# We can have a much simpler direct conversion between the two without passing by the PointingVersor
function _convert_different(::Type{E}, tp::ThetaPhi) where E <: AzEl
    (;θ,φ) = raw_properties(tp)
    ET = enforce_numbertype(E, tp)
    T = numbertype(ET)
    az = rem2pi(π/2 - φ, RoundNearest)
    el = π/2 - θ # Already in the [-90°, 90°] range
    constructor_without_checks(ET, SVector{2, T}(az, el))
end
function _convert_different(::Type{P}, p::AzEl) where P <: ThetaPhi
    (;az, el) = raw_properties(p)
    PT = enforce_numbertype(P, p)
    T = numbertype(PT)
    θ = π/2 - el
    φ = rem2pi(π/2 - az, RoundNearest)
    constructor_without_checks(PT, SVector{2, T}(θ, φ))
end

# AzEl <-> PointingVersor
#= Conversion from https://gssc.esa.int/navipedia/index.php/Transformations_between_ECEF_and_ENU_coordinates knowing that:
- p̂ ⋅ ê = u
- p̂ ⋅ n̂ = v
- p̂ ⋅ û = w
=#
function _convert_different(::Type{E}, p::PointingVersor) where E <: AzEl
    u,v,w = raw_svector(p)
    az = atan(u, v) # Already in the [-180°, 180°] range
    el = asin(w) # Already in the [-90°, 90°] range
    ET = enforce_numbertype(E, p)
    T = numbertype(ET)
    constructor_without_checks(ET, SVector{2, T}(az, el))
end
function _convert_different(::Type{P}, p::AzEl) where P <: PointingVersor
    (;az, el) = raw_properties(p)
    saz,caz = sincos(az)
    sel,cel = sincos(el)
    x = saz * cel
    y = caz * cel
    z = sel
    PT = enforce_numbertype(P, p)
    T = numbertype(PT)
    constructor_without_checks(PT, SVector{3, T}(x, y, z))
end

# ElOverAz <-> PointingVersor
function _convert_different(::Type{E}, p::PointingVersor) where E <: ElOverAz
    u,v,w = raw_svector(p)
    az = atan(-u,w) # Already in the [-180°, 180°] range
    el = asin(v) # Already in the [-90°, 90°] range
    ET = enforce_numbertype(E, p)
    T = numbertype(ET)
    constructor_without_checks(ET, SVector{2, T}(az, el))
end
function _convert_different(::Type{P}, p::ElOverAz) where P <: PointingVersor
    (;az, el) = raw_properties(p)
    saz,caz = sincos(az)
    sel,cel = sincos(el)
    x = -saz * cel
    y = sel
    z = caz * cel
    PT = enforce_numbertype(P, p)
    T = numbertype(PT)
    constructor_without_checks(PT, SVector{3, T}(x, y, z))
end

# AzOverEl <-> PointingVersor
function _convert_different(::Type{A}, p::PointingVersor) where A <: AzOverEl
    u,v,w = raw_svector(p)
    el = atan(v/w) # Already returns a value in the range [-90°, 90°]
    az = asin(-u) # This only returns the value in the [-90°, 90°] range
    # Make the angle compatible with our ranges of azimuth and elevation
    az = ifelse(w >= 0, az, copysign(180°, az) - az)
    AT = enforce_numbertype(A, p)
    T = numbertype(AT)
    constructor_without_checks(AT, SVector{2, T}(az, el))
end
function _convert_different(::Type{P}, p::AzOverEl) where P <: PointingVersor
    (;el, az) = raw_properties(p)
    sel,cel = sincos(el)
    saz,caz = sincos(az)
    x = -saz
    y = caz * sel
    z = caz * cel
    PT = enforce_numbertype(P, p)
    T = numbertype(PT)
    constructor_without_checks(PT, SVector{3, T}(x, y, z))
end

# Conversion fallbacks
# Conversion between non PointingVersor pointing types, passing through PointingVersor
function _convert_different(::Type{D}, p::S) where {D <: AbstractPointing, S <: AbstractPointing}
    pv = convert(PointingVersor, p)
    return convert(D, pv)
end

##### Base.isapprox #####
# PointingVersor
Base.isapprox(p1::PointingVersor, p2::PointingVersor; kwargs...) = isapprox(raw_svector(p1), raw_svector(p2); kwargs...)

# General isapprox method, passing via PointingVersor
Base.isapprox(p1::PointingVersor, p2::Union{UV, AngularPointing}; kwargs...) = isapprox(p1, convert(PointingVersor, p2); kwargs...)
Base.isapprox(p1::Union{UV, AngularPointing}, p2::PointingVersor; kwargs...) = isapprox(p2, p1; kwargs...)
Base.isapprox(p1::Union{UV, AngularPointing}, p2::Union{UV, AngularPointing}; kwargs...) = isapprox(convert(PointingVersor, p1), p2; kwargs...)

##### Random.rand #####
# PointingVersor
Random.rand(rng::AbstractRNG, ::Random.SamplerType{P}) where P <: PointingVersor =
    P((rand(rng) - .5 for _ in 1:3)...)
# UV
function Random.rand(rng::AbstractRNG, ::Random.SamplerType{U}) where U <: UV
    p = PointingVersor(rand(rng) - .5, rand(rng) - .5, rand(rng))
    UT = enforce_numbertype(U, p)
    T = numbertype(UT)
    constructor_without_checks(UT, SVector{2, T}(p.x, p.y))
end
# ThetaPhi
function Random.rand(rng::AbstractRNG, ::Random.SamplerType{TP}) where TP <: ThetaPhi
    θ = rand(rng) * π
    φ = rand(rng) * 2π - π
    TPT = enforce_numbertype(TP)
    T = numbertype(TPT)
    constructor_without_checks(TPT, SVector{2, T}(θ, φ))
end
# AzEl/AzOverEl/ElOverAz
function Random.rand(rng::AbstractRNG, ::Random.SamplerType{AE}) where AE <: Union{AzOverEl, ElOverAz, AzEl}
    az = rand(rng) * 2π - π
    el = rand(rng) * π - π/2
    AET = enforce_numbertype(AE)
    T = numbertype(AET)
    constructor_without_checks(AET, SVector{2, T}(az, el))
end

##### Utilities #####

###### Custom show overloads ######
PlutoShowHelpers.repl_summary(p::PointingVersor) = "PointingVersor"
PlutoShowHelpers.repl_summary(p::AbstractPointing) = shortname(p) * " Pointing"

PlutoShowHelpers.show_namedtuple(p::AngularPointing) = map(DualDisplayAngle, raw_properties(p))
