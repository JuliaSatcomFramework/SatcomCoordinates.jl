struct PointingVersor{T <: AbstractFloat} <: FieldVector{3, T}
    x::T
    y::T
    z::T

    BasicTypes.constructor_without_checks(::Type{PointingVersor{T}}, x, y, z) where T <: AbstractFloat = new{T}(x, y, z)
end
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


# UV
const UV_CONSTRUCTOR_TOLERANCE = Ref{Float64}(1e-5)

"""
    UV{T} <: AbstractPointing{T}

Specify a pointing direction in UV coordinates, which are identified by the
following relation with the standard (ISO/Physics) [spherical coordinates
representation](https://en.wikipedia.org/wiki/Spherical_coordinate_system):
- `u = sin(θ) * cos(φ)`
- `v = sin(θ) * sin(φ)`

# Note
UV coordinates can only be used to represent pointing direction in the
half-hemisphere containing the cartesian +Z axis.

# Fields
- `u::T`
- `v::T`

# Basic Constructors
	UV{T}(u,v)
The basic constructor takes 2 separate numbers `u`, `v` and instantiate the object assuming that `u^2 + v^2 <=
1` (condition for valid UV pointing), throwing an error otherwise.\\
If either of the inputs is `NaN`, the returned `ParametricUV` object will contain `NaN` for both fields.


	ParametricUV{T}(uv)
The `ParametricUV{T}` struct is a subtype of `FieldVector{2, T}` from `StaticArray` so
it can be created using any 2-element Tuple or Vector/StaticVector as input,
which will internally call the 2-arguments constructor.

See also: [`ThetaPhi`](@ref)
"""
struct UV{T <: AbstractFloat} <: FieldVector{2, T}
    u::T
    v::T
    BasicTypes.constructor_without_checks(::Type{UV{T}}, u, v) where {T} = new{T}(u, v)
end
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

function StaticArrays.adapt_eltype(::Type{SA}, x) where {SA <: Union{UV, PointingVersor}}
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

## Conversions UV <-> PointingVersor
Base.convert(::Type{PointingVersor{T}}, uv::UV) where T <: AbstractFloat = constructor_without_checks(PointingVersor{T}, uv.u, uv.v, sqrt(1 - uv.u^2 - uv.v^2))
function Base.convert(::Type{UV{T}}, pv::PointingVersor) where T <: AbstractFloat 
    @assert pv.z >= 0 "The provided PointingVersor is located in the half-hemisphere containing the cartesian -Z axis and can not be converted to UV coordinates"
    constructor_without_checks(UV{T}, pv.x, pv.y)
end


## ThetaPhi
"""
    ThetaPhi{T <: AbstractFloat} <: AngularPointing{T}

An object specifying a pointing direction in ThetaPhi coordinates, defined as the θ and φ in
the (ISO/Physics definition) [spherical coordinates
representation](https://en.wikipedia.org/wiki/Spherical_coordinate_system) 

# Fields
- `θ::Deg{T}`
- `φ::Deg{T}`

While the field name use the greek letters, the specific fields of an arbitrary
`ThetaPhi` object `tp` can be accessed with alternative symbols:
- `tp.θ`, `tp.theta` and `tp.t` can be used to access the `θ` field
- `tp.φ`, `tp.ϕ`, `tp.phi` and `tp.p` can be used to access the `φ` field

# Basic Constructors
	ThetaPhi(θ,φ)
The basic constructor takes 2 separate numbers `θ`, `φ` and instantiate the
object.\\
**Provided inputs are intepreted as degrees if not provided using angular quantities from Unitful.**
If either of the inputs is `NaN`, the returned `ThetaPhi` object will contain `NaN` for both fields.

	ThetaPhi(tp)
The `ThetaPhi` struct is a subtype of `FieldVector{2, Float64}` from `StaticArray` so
it can be created using any 2-element Tuple or Vector/StaticVector as input,
which will internally call the 2-arguments constructor.

See also: [`UV`](@ref)
"""
struct ThetaPhi{T <: AbstractFloat} <: AngularPointing{T}
	θ::Deg{T}
	φ::Deg{T}
    BasicTypes.constructor_without_checks(::Type{ThetaPhi{T}}, θ::Deg{T}, φ::Deg{T}) where {T <: AbstractFloat} = new{T}(θ, φ)
end
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

"""
    AzOverEl{T} <: AngularPointing{T}

Specify a pointing direction in Azimuth over Elevation coordinates. 
Following the notation in "Principles of Near Field Antenna Measurements" the Az and El values are related to the u, v, and w components of the `PointingVersor` by the following relations:
- Az = atan(w, -u)
- El = asin(v)

# Fields
- `az::Deg{T}`
- `el::Deg{T}`
"""
struct AzOverEl{T} <: AngularPointing{T}
    az::Deg{T}
    el::Deg{T}

    BasicTypes.constructor_without_checks(::Type{AzOverEl{T}}, az::Deg{T}, el::Deg{T}) where {T <: AbstractFloat} = new{T}(az, el)
end
function AzOverEl{T}(az, el) where T <: AbstractFloat
    f = to_degrees
    (isnan(az) || isnan(el)) && return constructor_without_checks(AzOverEl{T}, f(NaN), f(NaN))
    el = f(el)
    @assert -90° <= el <= 90° "The Elevation angle must be within the -90° and 90°, while $el was provided."
    constructor_without_checks(AzOverEl{T}, f(az, RoundNearest), el)
end

## Conversions AzOverEl <-> PointingVersor
function Base.convert(::Type{AzOverEl{T}}, p::PointingVersor) where T <: AbstractFloat
    (;u,v,w) = p
    az = atand(w, -u) |> to_degrees
    el = asind(v) |> to_degrees
    constructor_without_checks(AzOverEl{T}, az, el)
end


# Generic AngularPointing constructors
for AP in (:ThetaPhi,)
eval(:($AP(θ::Deg{T}, φ::Deg{T}) where {T <: Real} = $AP{T <: AbstractFloat ? T : Float64}(θ, φ)))
eval(:($AP(θ::T, φ::T) where {T <: Real} = $AP{T <: AbstractFloat ? T : Float64}(θ, φ)))
end

# This is to automatically extract the correct parametric subtype from Tuples/Arrays
function StaticArrays.adapt_eltype(::Type{AP}, x) where {AP <: AngularPointing}
    has_eltype(AP) && return AP
    T = if need_rewrap(AP, x)
        typeof(x)
    elseif x isa Tuple
        promote_tuple_eltype(x)
    elseif x isa Args
        promote_tuple_eltype(x.args)
    else
        eltype(x)
    end
    T <: Union{Real, Deg{<:Real}, Rad{<:Real}} || error("Objects of type $AP can only be created from real numbers or angular quantities from Unitful.jl (i.e. u\"rad\" or u\"°\")")
    T = numbertype(T)
    return AP{T <: AbstractFloat ? T : Float64}
end

### Abstract Pointing
"""
    const AbstractPointing{T} = Union{UV{T}, AngularPointing{T}, PointingVersor{T}}

Union type representing all of the possible Pointing types. Angular Pointing is
the only abstractype out of the 3 elements of the Union, while the other two are
concrete types themselves.
It needs to be a Union as `UV` and `PointingVersor` need to subtype `FieldVector` directly.
"""
const AbstractPointing{T} = Union{UV{T}, AngularPointing{T}, PointingVersor{T}}

### Fallbacks
# Conversion with PointingVersor with numbertype not specified
Base.convert(::Type{PointingVersor}, p::P) where {T <: AbstractFloat, P <: Union{UV{T}, AngularPointing{T}}} = convert(PointingVersor{T}, p)
Base.convert(::Type{P}, p::PointingVersor) where {P <: Union{UV, AngularPointing}} = convert(P{numbertype(p)}, p)

# Conversion between non PointingVersor pointing types, passing through PointingVersor
function Base.convert(::Type{D}, p::S) where {D <: Union{UV, AngularPointing}, S <: Union{UV, AngularPointing}}
    pv = convert(PointingVersor, p)
    return convert(D, pv)
end
