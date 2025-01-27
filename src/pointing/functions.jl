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

function StaticArrays.adapt_eltype(::Type{SA}, x) where {SA <: PointingVersor}
    has_eltype(SA) && return SA
    T = if need_rewrap(SA, x)
        typeof(x)
    elseif x isa Tuple
        promote_tuple_eltype(x)
    elseif x isa Args
        promote_tuple_eltype(x.args)
    else
        eltype(x)
    end
    T <: Real || error("Objects of type $SA can only be created from real numbers")
    return SA{T <: AbstractFloat ? T : Float64}
end


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

UV(u::T, v::T) where T <: Real = UV{T <: AbstractFloat ? T : Float64}(u, v)
UV(u::Real, v::Real) = UV(promote(u, v)...)


## Conversions UV <-> PointingVersor
Base.convert(::Type{PointingVersor{T}}, uv::UV) where T <: AbstractFloat = constructor_without_checks(PointingVersor{T}, uv.u, uv.v, sqrt(1 - uv.u^2 - uv.v^2))
function Base.convert(::Type{UV{T}}, pv::PointingVersor) where T <: AbstractFloat 
    @assert pv.z >= 0 "The provided PointingVersor is located in the half-hemisphere containing the cartesian -Z axis and can not be converted to UV coordinates"
    constructor_without_checks(UV{T}, pv.x, pv.y)
end

### ThetaPhi ###

function ThetaPhi{T}(θ, φ) where T <: AbstractFloat
    f = to_degrees
    (isnan(θ) || isnan(φ)) && return constructor_without_checks(ThetaPhi{T}, f(NaN), f(NaN))
    θ = f(θ)
    @assert 0° <= θ <= 180° "The Theta angle must be within the 0° and 180°, while $θ was provided."
    constructor_without_checks(ThetaPhi{T}, θ, f(φ, RoundNearest))
end

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


# ### AzOverEl ###
function (::Type{P})(az, el) where{T <: AbstractFloat, P <: Union{AzOverEl{T}, ElOverAz{T}}}
    (isnan(az) || isnan(el)) && return constructor_without_checks(AzOverEl{T}, f(NaN), f(NaN))
    el = to_degrees(el, RoundNearest)
    az = to_degrees(az, RoundNearest)
    el, az = wrap_first_angle_normalized(el, az)
    constructor_without_checks(AzOverEl{T}, az, el)
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


# # ElOverAz
# """
#     ElOverAz{T} <: AngularPointing{T}

# Specify a pointing direction in Elevation over Azimuth coordinates. 
# Following the notation in "Principles of Near Field Antenna Measurements" the Az and El values are related to the u, v, and w components of the `PointingVersor` by the following relations:
# - El = atan(v, w)
# - Az = asin(-u)

# # Fields
# - `el::Deg{T}`
# - `az::Deg{T}`
# """
# struct ElOverAz{T} <: AngularPointing{T}
#     el::Deg{T}
#     az::Deg{T}

#     BasicTypes.constructor_without_checks(::Type{ElOverAz{T}}, el::Deg{T}, az::Deg{T}) where {T <: AbstractFloat} = new{T}(el, az)
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

# # This is to automatically extract the correct parametric subtype from Tuples/Arrays
# function StaticArrays.adapt_eltype(::Type{AP}, x) where {AP <: AngularPointing}
#     has_eltype(AP) && return AP
#     T = if need_rewrap(AP, x)
#         typeof(x)
#     elseif x isa Tuple
#         promote_tuple_eltype(x)
#     elseif x isa Args
#         promote_tuple_eltype(x.args)
#     else
#         eltype(x)
#     end
#     T <: Union{Real, Deg{<:Real}, Rad{<:Real}} || error("Objects of type $AP can only be created from real numbers or angular quantities from Unitful.jl (i.e. u\"rad\" or u\"°\")")
#     T = numbertype(T)
#     return AP{T <: AbstractFloat ? T : Float64}
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

# ### Fallbacks
# # Conversion with PointingVersor with numbertype not specified
# Base.convert(::Type{PointingVersor}, p::P) where {T <: AbstractFloat, P <: Union{UV{T}, AngularPointing{T}}} = convert(PointingVersor{T}, p)
# Base.convert(::Type{P}, p::PointingVersor) where {P <: Union{UV, AngularPointing}} = convert(P{numbertype(p)}, p)

# # Conversion between non PointingVersor pointing types, passing through PointingVersor
# function Base.convert(::Type{D}, p::S) where {D <: Union{UV, AngularPointing}, S <: Union{UV, AngularPointing}}
#     pv = convert(PointingVersor, p)
#     return convert(D, pv)
# end
