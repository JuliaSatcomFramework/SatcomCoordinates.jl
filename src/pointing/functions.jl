# Pointing Versor
function PointingVersor{T}(x, y,z) where T <: AbstractFloat
    v = normalize(SVector{3, T}(x, y, z))
    return constructor_without_checks(PointingVersor{T}, v...)
end

to_svector(p::PointingVersor) = SVector{3, numbertype(p)}(p.x, p.y, p.z)

Base.isapprox(p1::PointingVersor, p2::PointingVersor; kwargs...) = isapprox(to_svector(p1), to_svector(p2); kwargs...)

function Base.getproperty(p::PointingVersor, s::Symbol)
    s ∈ (:x, :u) && return getfield(p, :x)
    s ∈ (:y, :v) && return getfield(p, :y)
    s ∈ (:z, :w) && return getfield(p, :z)
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


## Conversions UV <-> PointingVersor
Base.convert(::Type{PointingVersor{T}}, uv::UV) where T <: AbstractFloat = constructor_without_checks(PointingVersor{T}, uv.u, uv.v, sqrt(1 - uv.u^2 - uv.v^2))
function Base.convert(::Type{UV{T}}, pv::PointingVersor) where T <: AbstractFloat 
    @assert pv.z >= 0 "The provided PointingVersor is located in the half-hemisphere containing the cartesian -Z axis and can not be converted to UV coordinates"
    constructor_without_checks(UV{T}, pv.x, pv.y)
end
## Conversion UV <-> ThetaPhi
# Specific implementation for slightly faster conversion
function Base.convert(::Type{U}, tp::ThetaPhi) where U <: UV
	(;θ,φ) = tp
	@assert θ <= 90° "The provided ThetaPhi pointing $tp has θ > 90° so it lies in the half-hemisphere containing the -Z axis and can not be represented in UV"
	v, u = sin(θ) .* sincos(φ)
	return constructor_without_checks(enforce_numbertype(U, tp), u, v)
end
function Base.convert(::Type{TP}, uv::UV) where TP <: ThetaPhi
	(;u,v) = uv
	θ = asind(sqrt(u^2 + v^2)) |> to_degrees
	φ = atand(v,u) |> to_degrees
	return constructor_without_checks(enforce_numbertype(TP, uv), θ, φ)
end

### ThetaPhi ###
# getproperty
function Base.getproperty(p::ThetaPhi, s::Symbol)
    s ∈ (:t, :θ, :theta) && return getfield(p, :θ)
    s ∈ (:p, :φ, :ϕ, :phi) && return getfield(p, :φ)
end

## Conversions ThetaPhi <-> PointingVersor
function Base.convert(::Type{PointingVersor{T}}, tp::ThetaPhi) where T <: AbstractFloat 
	(; θ, φ) = tp
	sθ,cθ = sincos(θ)
	sφ,cφ = sincos(φ)
	x = sθ * cφ
	y = sθ * sφ 
	z = cθ
    constructor_without_checks(PointingVersor{T}, x, y, z)
end
function Base.convert(::Type{ThetaPhi{T}}, pv::PointingVersor) where T <: AbstractFloat 
	(;x,y,z) = pv
	θ = acosd(z) |> to_degrees
	φ = atand(y,x) |> to_degrees
    constructor_without_checks(ThetaPhi{T}, θ, φ)
end


### AzOverEl/ElOverAz ###


function (::Type{P})(α, β) where{T <: AbstractFloat, P <: Union{AzOverEl{T}, ElOverAz{T}, ThetaPhi{T}}}
    (isnan(α) || isnan(β)) && return constructor_without_checks(P, f(NaN), f(NaN))
    α = to_degrees(α, RoundNearest)
    β = to_degrees(β, RoundNearest)
    α, β = wrap_spherical_angles_normalized(α, β, P)
    constructor_without_checks(P, α, β)
end

# getproperty
function Base.getproperty(p::Union{AzOverEl, ElOverAz}, s::Symbol)
    s ∈ (:az, :azimuth) && return getfield(p, :az)
    s ∈ (:el, :elevation) && return getfield(p, :el)
end

## Conversions ElOverAz <-> PointingVersor
function Base.convert(P::Type{ElOverAz{T}}, p::PointingVersor) where T <: AbstractFloat
    (;u,v,w) = p
    az = atand(-u,w) |> to_degrees # Already in the [-180°, 180°] range
    el = asind(v) |> to_degrees # Already in the [-90°, 90°] range
    constructor_without_checks(P, az, el)
end
function Base.convert(::Type{PointingVersor{T}}, p::ElOverAz) where T <: AbstractFloat
    (;az, el) = p
    saz,caz = sincos(az)
    sel,cel = sincos(el)
    x = -saz * cel
    y = sel
    z = caz * cel
    constructor_without_checks(PointingVersor{T}, x, y, z)
end


## Conversions AzOverEl <-> PointingVersor
function Base.convert(P::Type{AzOverEl{T}}, p::PointingVersor) where T <: AbstractFloat
    (;u,v,w) = p
    el = atand(v/w) |> to_degrees # Already returns a value in the range [-90°, 90°]
    az = asind(-u) |> to_degrees # This only returns the value in the [-90°, 90°] range
    # Make the angle compatible with our ranges of azimuth and elevation
    az = ifelse(w >= 0, az, copysign(180°, az) - az)
    constructor_without_checks(P, az, el)
end
function Base.convert(::Type{PointingVersor{T}}, p::AzOverEl) where T <: AbstractFloat
    (;el, az) = p
    sel,cel = sincos(el)
    saz,caz = sincos(az)
    x = -saz
    y = caz * sel
    z = caz * cel
    constructor_without_checks(PointingVersor{T}, x, y, z)
end

### Fallbacks
# Constructors without numbertype, and with tuple or SVector as input
for P in (:UV, :ThetaPhi, :AzOverEl, :ElOverAz, :PointingVersor)
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

# Angular pointing version with Tuple/SVector as input
(::Type{P})(pt::Point2D) where P <: AngularPointing = P(pt...)

# Trivial conversions
for P in (:UV, :ThetaPhi, :AzOverEl, :ElOverAz, :PointingVersor)
    eval(:(Base.convert(::Type{$P}, p::$P) = p))
    eval(:(Base.convert(::Type{$P{T}}, p::$P{T}) where T = p))
    eval(:(Base.convert(::Type{$P{T}}, p::$P{S}) where {T, S} = $P{T}(getfields(p)...)))
end

# Conversion with PointingVersor with numbertype not specified
Base.convert(::Type{PointingVersor}, p::P) where {T <: AbstractFloat, P <: AbstractPointing{T}} = convert(PointingVersor{T}, p)
Base.convert(::Type{P}, p::PointingVersor) where {P <: AbstractPointing} = convert(P{numbertype(p)}, p)

# Conversion between non PointingVersor pointing types, passing through PointingVersor
function Base.convert(::Type{D}, p::S) where {D <: AbstractPointing, S <: AbstractPointing}
    pv = convert(PointingVersor, p)
    return convert(D, pv)
end

# General isapprox method
Base.isapprox(p1::PointingVersor, p2::Union{UV, AngularPointing}; kwargs...) = isapprox(p1, convert(PointingVersor, p2); kwargs...)
Base.isapprox(p1::Union{UV, AngularPointing}, p2::PointingVersor; kwargs...) = isapprox(p2, p1; kwargs...)
Base.isapprox(p1::Union{UV, AngularPointing}, p2::Union{UV, AngularPointing}; kwargs...) = isapprox(convert(PointingVersor, p1), p2; kwargs...)

# Rand methods
Random.rand(rng::AbstractRNG, ::Random.SamplerType{P}) where P <: PointingVersor =
    P((rand(rng) - .5 for _ in 1:3)...)

function Random.rand(rng::AbstractRNG, ::Random.SamplerType{U}) where U <: UV
    p = PointingVersor(rand(rng) - .5, rand(rng) - .5, rand(rng))
    constructor_without_checks(enforce_numbertype(U), p.x, p.y)
end

function Random.rand(rng::AbstractRNG, ::Random.SamplerType{TP}) where TP <: ThetaPhi
    θ = rand(rng) * 180°
    φ = rand(rng) * 360° - 180°
    constructor_without_checks(enforce_numbertype(TP), θ, φ)
end

function Random.rand(rng::AbstractRNG, ::Random.SamplerType{AE}) where AE <: Union{AzOverEl, ElOverAz}
    az = rand(rng) * 360° - 180°
    el = rand(rng) * 180° - 90°
    constructor_without_checks(enforce_numbertype(AE), az, el)
end