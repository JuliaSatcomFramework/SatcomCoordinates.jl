# Pointing Versor
function PointingVersor{T}(x,y,z) where T <: AbstractFloat
    v = normalize(SVector{3, T}(x, y, z))
    return constructor_without_checks(PointingVersor{T}, v...)
end
PointingVersor(x::T, y::T, z::T) where T <: Real = PointingVersor{T <: AbstractFloat ? T : Float64}(x, y, z)
PointingVersor(x::Real, y::Real, z::Real) = PointingVersor(promote(x, y, z)...)

function Base.getproperty(p::PointingVersor, s::Symbol)
    s ∈ (:x, :u) && return getfield(p, :x)
    s ∈ (:y, :v) && return getfield(p, :y)
    s ∈ (:z, :w) && return getfield(p, :z)
end

(::Type{P})(pt::Point{3, Real}) where P <: PointingVersor = P(pt[1], pt[2], pt[3])

# Trivial conversions
Base.convert(::Type{PointingVersor}, p::PointingVersor) = p
Base.convert(::Type{PointingVersor{T}}, p::PointingVersor{T}) where T <: AbstractFloat = p
Base.convert(::Type{PointingVersor{T}}, p::PointingVersor) where T <: AbstractFloat = constructor_without_checks(PointingVersor{T}, p.x, p.y, p.z)

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

(::Type{P})(pt::Point{2, Real}) where P <: UV = P(pt[1], pt[2])


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
	@assert θ <= 90° "The provided ThetaPhi pointing $tp has θ > 90° so it can not be represented in UV"
	v, u = sin(θ) .* sincos(φ)
    T = has_eltype(U) ? U : U{numbertype(tp)}
	return constructor_without_checks(T, u, v)
end
function Base.convert(::Type{TP}, uv::UV) where TP <: ThetaPhi
	(;u,v) = uv
	θ = asind(sqrt(u^2 + v^2)) |> to_degrees
	φ = atand(v,u) |> to_degrees
    T = has_eltype(TP) ? TP : TP{numbertype(uv)}
	return constructor_without_checks(T, θ, φ)
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

# ## Conversions AzOverEl <-> PointingVersor
# function Base.convert(::Type{AzOverEl{T}}, p::PointingVersor) where T <: AbstractFloat
#     (;u,v,w) = p
#     az = atand(-u,w) |> to_degrees
#     el = asind(v) |> to_degrees
#     constructor_without_checks(AzOverEl{T}, az, el)
# end
# function Base.convert(::Type{PointingVersor{T}}, p::AzOverEl) where T <: AbstractFloat
#     (;az, el) = p
#     saz,caz = sincos(az)
#     sel,cel = sincos(el)
#     x = -saz * cel
#     y = sel
#     z = caz * cel
#     constructor_without_checks(PointingVersor{T}, x, y, z)
# end


# ## Conversions ElOverAz <-> PointingVersor
# function Base.convert(::Type{ElOverAz{T}}, p::PointingVersor) where T <: AbstractFloat
#     (;u,v,w) = p
#     el = atand(v, w) |> to_degrees
#     az = asind(-u) |> to_degrees
#     constructor_without_checks(ElOverAz{T}, el, az)
# end
# function Base.convert(::Type{PointingVersor{T}}, p::ElOverAz) where T <: AbstractFloat
#     (;el, az) = p
#     sel,cel = sincos(el)
#     saz,caz = sincos(az)
#     x = -saz
#     y = caz * sel
#     z = caz * cel
#     constructor_without_checks(PointingVersor{T}, x, y, z)
# end

# # Generic AngularPointing constructors
# for AP in (:ThetaPhi, :AzOverEl, :ElOverAz)
# eval(:($AP(a1::Deg{T}, a2::Deg{T}) where {T <: Real} = $AP{T <: AbstractFloat ? T : Float64}(a1, a2)))
# eval(:($AP(a1::T, a2::T) where {T <: Real} = $AP{T <: AbstractFloat ? T : Float64}(a1, a2)))
# eval(:($AP(a1::ValidAngle, a2::ValidAngle) = $AP{promote_type(numbertype(a1), numbertype(a2))}(a1, a2)))
# end


# ### Abstract Pointing
# """
#     const AbstractPointing{T} = Union{UV{T}, AngularPointing{T}, PointingVersor{T}}

# Union type representing all of the possible Pointing types. Angular Pointing is
# the only abstractype out of the 3 elements of the Union, while the other two are
# concrete types themselves.
# It needs to be a Union as `UV` and `PointingVersor` need to subtype `FieldVector` directly.
# """
# const AbstractPointing{T} = Union{UV{T}, AngularPointing{T}, PointingVersor{T}}

### Fallbacks
# Constructors without numbertype, and with tuple or SVector as input
for P in (:UV, :ThetaPhi, :AzOverEl, :ElOverAz)
    NT = P === :UV ? :Real : :ValidAngle
    eval(:(
    function $P(a1::$NT, a2::$NT) 
        T = promote_type(numbertype(a1), numbertype(a2))
        T = T <: AbstractFloat ? T : Float64
        $P{T}(a1, a2)
    end
    ))
end

# Angular pointing version with Tuple/SVector as input
(::Type{P})(pt::Point2D) where P <: AngularPointing = P(pt[1], pt[2])
# AbstractPointing version with AbstractVector
function (::Type{P})(pt::AbstractVector) where P <: AbstractPointing
    @assert length(pt) == 2 "The provided vector must have 2 elements"
    P(pt[1], pt[2])
end
function (::Type{P})(pt::AbstractVector) where {P <: PointingVersor}
    @assert length(pt) == 3 "The provided vector must have 3 elements"
    P(pt[1], pt[2], pt[3])
end

# Conversion with PointingVersor with numbertype not specified
Base.convert(::Type{PointingVersor}, p::P) where {T <: AbstractFloat, P <: AbstractPointing{T}} = convert(PointingVersor{T}, p)
Base.convert(::Type{P}, p::PointingVersor) where {P <: AbstractPointing} = convert(P{numbertype(p)}, p)

# Conversion between non PointingVersor pointing types, passing through PointingVersor
function Base.convert(::Type{D}, p::S) where {D <: AbstractPointing, S <: AbstractPointing}
    pv = convert(PointingVersor, p)
    return convert(D, pv)
end
