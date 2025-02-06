##### Constructors #####

# Pointing Versor
function PointingVersor{T}(x, y, z) where T <: AbstractFloat
    v = normalize(SVector{3, T}(x, y, z))
    return constructor_without_checks(PointingVersor{T}, v...)
end

(::Type{P})(pt::Point{3, Real}) where P <: PointingVersor = P(pt...)

# UV
const UV_CONSTRUCTOR_TOLERANCE = Ref{Float64}(1e-5)

function UV{T}(u, v) where {T <: AbstractFloat}
    (isnan(u) || isnan(v)) && return constructor_without_checks(UV{T}, NaN, NaN)
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
    constructor_without_checks(UV{T}, u, v)
end

(::Type{P})(pt::Point{2, Real}) where P <: UV = P(pt...)

# AngularPointing
function (::Type{P})(α, β) where{T <: AbstractFloat, P <: Union{AzOverEl{T}, ElOverAz{T}, ThetaPhi{T}, AzEl{T}}}
    (isnan(α) || isnan(β)) && return constructor_without_checks(P, f(NaN), f(NaN))
    α = to_degrees(α, RoundNearest)
    β = to_degrees(β, RoundNearest)
    α, β = wrap_spherical_angles_normalized(α, β, P)
    constructor_without_checks(P, α, β)
end
(::Type{P})(pt::Point2D) where P <: AngularPointing = P(pt...)

# Constructors without numbertype, and with tuple or SVector as input
for P in (:UV, :ThetaPhi, :AzEl, :AzOverEl, :ElOverAz, :PointingVersor)
    NT = P in (:UV, :PointingVersor) ? :Real : :ValidAngle
    N = P === :PointingVersor ? 3 : 2
    eval(:(
    function $P(vals::Vararg{$NT, $N})
        T = promote_type(map(numbertype, vals)...)
        T = T <: AbstractFloat ? T : Float64
        $P{T}(vals...)
    end
    ))
end

##### Conversions #####
# UV <-> PointingVersor
_convert_different(::Type{P}, uv::UV) where {P <: PointingVersor} = constructor_without_checks(enforce_numbertype(P, uv), uv.u, uv.v, sqrt(1 - uv.u^2 - uv.v^2))
function _convert_different(::Type{U}, pv::PointingVersor) where U <: UV 
    @assert pv.z >= 0 "The provided PointingVersor is located in the half-hemisphere containing the cartesian -Z axis and can not be converted to UV coordinates"
    constructor_without_checks(enforce_numbertype(U, pv), pv.x, pv.y)
end

# ThetaPhi <-> UV (Specific implementation for slightly faster conversion)
function _convert_different(::Type{U}, tp::ThetaPhi) where U <: UV
	(;θ,φ) = tp
	@assert θ <= 90° "The provided ThetaPhi pointing $tp has θ > 90° so it lies in the half-hemisphere containing the -Z axis and can not be represented in UV"
	v, u = sin(θ) .* sincos(φ)
	return constructor_without_checks(enforce_numbertype(U, tp), u, v)
end
function _convert_different(::Type{TP}, uv::UV) where TP <: ThetaPhi
	(;u,v) = uv
	θ = asin(sqrt(u^2 + v^2)) |> asdeg
	φ = atan(v,u) |> asdeg
	return constructor_without_checks(enforce_numbertype(TP, uv), θ, φ)
end

# ThetaPhi <-> PointingVersor
function _convert_different(::Type{P}, tp::ThetaPhi) where P <: PointingVersor
	(; θ, φ) = raw_nt(tp)
	sθ,cθ = sincos(θ)
	sφ,cφ = sincos(φ)
	x = sθ * cφ
	y = sθ * sφ 
	z = cθ
    constructor_without_checks(enforce_numbertype(P, tp), x, y, z)
end
function _convert_different(::Type{TP}, pv::PointingVersor) where TP <: ThetaPhi
	(;x,y,z) = pv
	θ = acos(z) |> asdeg
	φ = atan(y,x) |> asdeg
    constructor_without_checks(enforce_numbertype(TP, pv), θ, φ)
end

# ThetaPhi <-> AzEl
# We can have a much simpler direct conversion between the two without passing by the PointingVersor
function _convert_different(::Type{E}, tp::ThetaPhi) where E <: AzEl
    (;θ,φ) = tp
    az = rem(90° - φ, 360°, RoundNearest)
    el = 90° - θ # Already in the [-90°, 90°] range
    constructor_without_checks(enforce_numbertype(E, tp), az, el)
end
function _convert_different(::Type{P}, p::AzEl) where P <: ThetaPhi
    (;az, el) = p
    θ = 90° - el
    φ = rem(90° - az, 360°, RoundNearest)
    constructor_without_checks(enforce_numbertype(P, p), θ, φ)
end

# AzEl <-> PointingVersor
#= Conversion from https://gssc.esa.int/navipedia/index.php/Transformations_between_ECEF_and_ENU_coordinates knowing that:
- p̂ ⋅ ê = u
- p̂ ⋅ n̂ = v
- p̂ ⋅ û = w
=#
function _convert_different(::Type{E}, p::PointingVersor) where E <: AzEl
    (;u,v,w) = p
    az = atan(u, v) |> asdeg # Already in the [-180°, 180°] range
    el = asin(w) |> asdeg # Already in the [-90°, 90°] range
    constructor_without_checks(enforce_numbertype(E, p), az, el)
end
function _convert_different(::Type{P}, p::AzEl) where P <: PointingVersor
    (;az, el) = raw_nt(p)
    saz,caz = sincos(az)
    sel,cel = sincos(el)
    x = saz * cel
    y = caz * cel
    z = sel
    constructor_without_checks(enforce_numbertype(P, p), x, y, z)
end

# ElOverAz <-> PointingVersor
function _convert_different(::Type{E}, p::PointingVersor) where E <: ElOverAz
    (;u,v,w) = p
    az = atan(-u,w) |> asdeg # Already in the [-180°, 180°] range
    el = asin(v) |> asdeg # Already in the [-90°, 90°] range
    constructor_without_checks(enforce_numbertype(E, p), az, el)
end
function _convert_different(::Type{P}, p::ElOverAz) where P <: PointingVersor
    (;az, el) = raw_nt(p)
    saz,caz = sincos(az)
    sel,cel = sincos(el)
    x = -saz * cel
    y = sel
    z = caz * cel
    constructor_without_checks(enforce_numbertype(P, p), x, y, z)
end

# AzOverEl <-> PointingVersor
function _convert_different(::Type{A}, p::PointingVersor) where A <: AzOverEl
    (;u,v,w) = p
    el = atan(v/w) |> asdeg # Already returns a value in the range [-90°, 90°]
    az = asin(-u) |> asdeg # This only returns the value in the [-90°, 90°] range
    # Make the angle compatible with our ranges of azimuth and elevation
    az = ifelse(w >= 0, az, copysign(180°, az) - az)
    constructor_without_checks(enforce_numbertype(A, p), az, el)
end
function _convert_different(::Type{P}, p::AzOverEl) where P <: PointingVersor
    (;el, az) = raw_nt(p)
    sel,cel = sincos(el)
    saz,caz = sincos(az)
    x = -saz
    y = caz * sel
    z = caz * cel
    constructor_without_checks(enforce_numbertype(P, p), x, y, z)
end

# Conversion fallbacks
# Conversion between non PointingVersor pointing types, passing through PointingVersor
function _convert_different(::Type{D}, p::S) where {D <: AbstractPointing, S <: AbstractPointing}
    pv = convert(PointingVersor, p)
    return convert(D, pv)
end

##### Base.getproperty #####
# PointingVersor
function Base.getproperty(p::PointingVersor, s::Symbol)
    s ∈ (:x, :u) && return getfield(p, :x)
    s ∈ (:y, :v) && return getfield(p, :y)
    s ∈ (:z, :w) && return getfield(p, :z)
    throw(ArgumentError("Objects of type `PointingVersor` do not have a property called $s"))
end

# ThetaPhi
function Base.getproperty(p::ThetaPhi, s::Symbol)
    s ∈ (:t, :θ, :theta) && return getfield(p, :θ)
    s ∈ (:p, :φ, :ϕ, :phi) && return getfield(p, :φ)
    throw(ArgumentError("Objects of type `ThetaPhi` do not have a property called $s"))
end

# AzEl/AzOverEl/ElOverAz
function Base.getproperty(p::Union{AzOverEl, ElOverAz, AzEl}, s::Symbol)
    s ∈ (:az, :azimuth) && return getfield(p, :az)
    s ∈ (:el, :elevation) && return getfield(p, :el)
    throw(ArgumentError("Objects of type `$(p |> typeof |> basetype)` do not have a property called $s"))
end

##### Base.isapprox #####
# PointingVersor
Base.isapprox(p1::PointingVersor, p2::PointingVersor; kwargs...) = isapprox(to_svector(p1), to_svector(p2); kwargs...)

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
    constructor_without_checks(enforce_numbertype(U), p.x, p.y)
end
# ThetaPhi
function Random.rand(rng::AbstractRNG, ::Random.SamplerType{TP}) where TP <: ThetaPhi
    θ = rand(rng) * 180°
    φ = rand(rng) * 360° - 180°
    constructor_without_checks(enforce_numbertype(TP), θ, φ)
end
# AzEl/AzOverEl/ElOverAz
function Random.rand(rng::AbstractRNG, ::Random.SamplerType{AE}) where AE <: Union{AzOverEl, ElOverAz, AzEl}
    az = rand(rng) * 360° - 180°
    el = rand(rng) * 180° - 90°
    constructor_without_checks(enforce_numbertype(AE), az, el)
end

##### Utilities #####
to_svector(p::PointingVersor) = SVector{3, numbertype(p)}(p.x, p.y, p.z)

###### Custom show overloads ######
PlutoShowHelpers.repl_summary(p::AbstractPointing) = shortname(p) * " Pointing"

PlutoShowHelpers.show_namedtuple(p::AngularPointing) = map(DualDisplayAngle, raw_nt(p))