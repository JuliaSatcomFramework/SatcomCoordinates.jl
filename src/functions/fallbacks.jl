# # Addition, subtraction and sign inversion
function Base.:(-)(c::AbstractPosition) 
    trait = position_trait(c)
    applicable(_negate_position, trait, c) || throw(ArgumentError("Cannot negate coordinates of type $(typeof(c))"))
    _negate_position(trait, c)
end
_negate_position(::CartesianPositionTrait, c::AbstractPosition) = constructor_without_checks(typeof(c), -raw_svector(c))

function Base.:(+)(c1::C1, c2::C2) where {C1 <: AbstractPosition, C2 <: AbstractPosition} 
    C = basetype(C1)
    C == basetype(C2) || throw(ArgumentError("Cannot add coordinates of different types: $C1 and $C2"))
    trait = position_trait(C1)
    applicable(_sum_positions, trait, c1, c2) || throw(ArgumentError("Cannot add coordinates of type $(basetype(c1))"))
    return _sum_positions(trait, c1, c2)
end
function _sum_positions(::CartesianPositionTrait, c1::AbstractPosition, c2::AbstractPosition)
    T = promote_type(numbertype(c1), numbertype(c2))
    sv = raw_svector(c1) + raw_svector(c2) |> change_numbertype(T)
    constructor_without_checks(basetype(c1){T}, sv)
end
Base.:(-)(c1::C1, c2::C2) where {C1 <: AbstractPosition, C2 <: AbstractPosition} = c1 + (-c2)

#### Properties ####

Base.propertynames(p::AbstractSatcomCoordinate) = properties_names(typeof(p))

properties_names(::Type{<:AbstractPosition{<:Any, 3}}) = (:x, :y, :z)

ConstructionBase.getproperties(p::AbstractSatcomCoordinate) = raw_properties(p)
# For positions we resort to a Trait to dispatch on whether it's Cartesian or AngleAngleDistance
ConstructionBase.getproperties(p::AbstractPosition) = _position_properties(position_trait(p), p)

_position_properties(::CartesianPositionTrait, p::AbstractPosition) = map(to_meters, raw_properties(p))
function _position_properties(::SphericalPositionTrait, p::AbstractPosition{T, 3}) where T
    a1, a2, r = raw_svector(p)
    nms = propertynames(p)
    return NamedTuple{nms}((asdeg(a1), asdeg(a2), to_meters(r)))
end

function Base.getproperty(p::AbstractSatcomCoordinate, s::Symbol)
    s in propertynames(p) || throw(ArgumentError("Property $s is not a valid property for objects of type $(typeof(p))"))
    nt = getproperties(p)
    return getproperty(nt, s)
end

# This function should take as input independent 
function construct_inner_svector end

function construct_inner_svector(::Type{<:AbstractPosition{T, N}}, args::Vararg{PS, N}) where {T <: AbstractFloat, N}
    return SVector{N, T}(args...)
end

svector_size(::Type{<:StaticVector{N}}) where N = return N
svector_size(::Type{<:AbstractSatcomCoordinate{<:Any, N}}) where N = return N

function (P::Type{<:Union{AbstractSatcomCoordinate, AbstractFieldValue}})(::Val{NaN})
    PT = enforce_numbertype(P)
    T = numbertype(PT)
    N = svector_size(PT)
    sv = ntuple(_ -> T(NaN), N) |> SVector{N, T}
    return constructor_without_checks(PT, sv)
end

function (P::Type{<:Union{AbstractSatcomCoordinate{<:Any, N}, AbstractFieldValue}})(args::Vararg{Number, N}) where N
    PT = enforce_numbertype(P, default_numbertype(args...))
    any(isnan, args) && return PT(Val{NaN}())
    v = construct_inner_svector(PT, args...)
    return constructor_without_checks(PT, v)
end
(P::Type{<:AbstractSatcomCoordinate{<:Any, N}})(coords::Point{N, PS}) where N = P(coords...)

# zero
function Base.zero(C::Type{<:AbstractPosition})
    trait = position_trait(C)
    applicable(_zero_position, trait, C) || throw(ArgumentError("Base.zero is not defined for coordinates of type $C"))
    return _zero_position(trait, C)
end
function _zero_position(::CartesianPositionTrait, C::Type{<:AbstractPosition}) 
    CT = enforce_numbertype(C)
    T = numbertype(CT)
    constructor_without_checks(CT, zero(SVector{3, T}))
end

# isnan
Base.isnan(x::Union{AbstractSatcomCoordinate, AbstractFieldValue}) = any(isnan, raw_properties(x))

# isapprox
function Base.isapprox(c1::AbstractPosition, c2::AbstractPosition; kwargs...)
    C1 = typeof(c1)
    C2 = typeof(c2)
    basetype(C1) == basetype(C2) || throw(ArgumentError("Cannot compare coordinates of different types: $C1 and $C2"))
    return isapprox_position(position_trait(c1), c1, c2; kwargs...)
end
isapprox_position(::CartesianPositionTrait, c1::AbstractPosition, c2::AbstractPosition; kwargs...) = isapprox(raw_svector(c1), raw_svector(c2); kwargs...)

# Rand for AbstractPosition
function Random.rand(rng::AbstractRNG, ::Random.SamplerType{L}) where L <: AbstractPosition{<:Any, 3}
    C = enforce_numbertype(L)
    T = numbertype(C)
    p = rand(rng, PointingVersor{T}) |> raw_svector
    sv = p * (1e3 * ((1 + rand(rng)))) |> change_numbertype(T)
    constructor_without_checks(C, sv)
end

function Base.convert(::Type{C1}, c::C2) where {C1 <: AbstractSatcomCoordinate, C2 <: AbstractSatcomCoordinate}
    isnan(c) && return enforce_numbertype(C1, c)(Val{NaN}())
    if basetype(C1) == basetype(C2)
        _convert_same(C1, c)
    else
        _convert_different(C1, c)
    end
end

function _convert_same(::Type{C}, c::C) where C <: AbstractSatcomCoordinate
    return c
end
function _convert_same(::Type{C1}, c::C2) where {C1 <: AbstractSatcomCoordinate, C2 <: AbstractSatcomCoordinate}
    has_numbertype(C1) || return c # If numbertype was specified, we don't need to convert
    T = numbertype(C1)
    sv = change_numbertype(T, raw_svector(c))
    return constructor_without_checks(C1, sv)
end

function _convert_different(::Type{C1}, c::C2) where {C1 <: AbstractSatcomCoordinate, C2 <: AbstractSatcomCoordinate}
    throw(ArgumentError("Cannot convert coordinates of different types: $C1 and $C2"))
end

##### Numbertype interface #####
# numbertype
# Generic versions not on types of this package
numbertype(::Type{<:Quantity{T}}) where T  = T
numbertype(::Type{T}) where T <: Real = T
numbertype(::T) where T = numbertype(T)
numbertype(T::DataType) = error("The numbertype function is not implemented for type $T")
numbertype(::Type{<:AbstractArray{T}}) where T = T
# Implementation for our own types
numbertype(::Type{<:WithNumbertype{T}}) where T = T
numbertype(T::Type{<:WithNumbertype}) = error("The provided UnionAll type $T does not have the numbertype parameter specified")

# has_numbertype
# This is inspired from StaticArrays. These are not onlineners as coverage otherwise do not catch them.
has_numbertype(::Type{<:WithNumbertype{T}}) where {T} = return true
has_numbertype(::Type{<:WithNumbertype}) = return false

# enforce_numbertype
enforce_numbertype(::Type{C}, ::Type{T}) where {C, T <: Real} =
    has_numbertype(C) ? C : C{T}
enforce_numbertype(::Type{C}, default::T = 1.0) where {C, T} =
    enforce_numbertype(C, numbertype(T))

# change_numbertype
# Fallbacks for types not defined in this package
change_numbertype(::Type{T}, x::Real) where T <: AbstractFloat = convert(T, x)
change_numbertype(::Type{T}, x::SVector{N}) where {T <: Real, N} = convert(SVector{N, T}, x)
change_numbertype(::Type{T}, r::RotMatrix3) where {T <: AbstractFloat} = convert(RotMatrix3{T}, r)
change_numbertype(::Type, i::Identity) = i
change_numbertype(::Type{T}, x::Deg) where T <: AbstractFloat = convert(Deg{T}, x)
change_numbertype(::Type{T}, x::Met) where T <: AbstractFloat = convert(Met{T}, x)

# Functor which fix the numbertype to change to
change_numbertype(::Type{T}) where T <: AbstractFloat = return Base.Fix1(change_numbertype, T)

# Generic fallback for own types calling convert
change_numbertype(::Type{T}, c::C) where {T <: AbstractFloat, C <: WithNumbertype} = return convert(basetype(C){T}, c)

# Overload show method
# Basic overloads
Base.show(io::IO, mime::MIME"text/plain", x::WithNumbertype) = show(io, mime, DefaultShowOverload(x))
Base.show(io::IO, mime::MIME"text/html", x::WithNumbertype) = show(io, mime, DefaultShowOverload(x))
Base.show(io::IO, x::WithNumbertype) = show(io, DefaultShowOverload(x))

PlutoShowHelpers.shortname(x::AbstractSatcomCoordinate) = x |> typeof |> basetype |> nameof |> string

PlutoShowHelpers.repl_summary(p::AbstractSatcomCoordinate) = shortname(p) * " Coordinate"

PlutoShowHelpers.show_namedtuple(c::AbstractSatcomCoordinate) = getproperties(c)

PlutoShowHelpers.show_namedtuple(p::AbstractPosition) = _show_namedtuple(position_trait(p), p)
_show_namedtuple(::CartesianPositionTrait, p::AbstractPosition) = map(DisplayLength, raw_properties(p))
function _show_namedtuple(::SphericalPositionTrait, p::AbstractPosition) 
    nms = propertynames(p)
    a1, a2, r = raw_svector(p)
    return NamedTuple{nms}((
        DualDisplayAngle(a1),
        DualDisplayAngle(a2),
        DisplayLength(r)
    ))
end
