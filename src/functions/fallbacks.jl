# # Addition, subtraction and sign inversion
# Base.:(-)(c::C) where C <: CartesianPosition = constructor_without_checks(C, -c.x, -c.y, -c.z)
# function Base.:(+)(c1::C1, c2::C2) where {C1 <: CartesianPosition, C2 <: CartesianPosition} 
#     C = basetype(C1)
#     C == basetype(C2) || throw(ArgumentError("Cannot add coordinates of different types: $C1 and $C2"))
#     T = promote_type(numbertype(C1), numbertype(C2))
#     constructor_without_checks(C{T}, c1.x + c2.x, c1.y + c2.y, c1.z + c2.z)
# end
# Base.:(-)(c1::C1, c2::C2) where {C1 <: CartesianPosition, C2 <: CartesianPosition} = c1 + (-c2)

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
    return NamedTuple{nms}(asdeg(a1), asdeg(a2), to_meters(r))
end

function Base.getproperty(p::AbstractSatcomCoordinate, s::Symbol)
    s in propertynames(p) || throw(ArgumentError("Property $s is not a valid property for objects of type $(typeof(p))"))
    nt = getproperties(p)
    return getproperty(nt, s)
end

# This function should take as input independent 
function construct_inner_svector end

function construct_inner_svector(::Type{<:AbstractPosition{T, N}}, args::Vararg{Real, N}) where {T <: AbstractFloat, N}
    return SVector{N, T}(args...)
end

svector_size(::Type{<:StaticVector{N}}) where N = N
svector_size(T::Type{<:AbstractSatcomCoordinate}) = svector_size(fieldtypes(enforce_numbertype(T)) |> first)

function (P::Type{<:AbstractSatcomCoordinate})(::Val{NaN})
    PT = enforce_numbertype(P)
    T = numbertype(PT)
    N = svector_size(PT)
    sv = ntuple(_ -> T(NaN), N) |> SVector{N, T}
    return constructor_without_checks(PT, sv)
end

function (P::Type{<:AbstractSatcomCoordinate{<:Any, N}})(args::Vararg{Any, N}) where N
    PT = enforce_numbertype(P, default_numbertype(args...))
    any(isnan, args) && return PT(Val{NaN}())
    v = construct_inner_svector(PT, args...)
    return constructor_without_checks(PT, v)
end
(P::Type{<:AbstractSatcomCoordinate{<:Any, N}})(coords::Point{N}) where N = P(coords...)

# # zero
# Base.zero(::Type{C}) where C <: CartesianPosition = constructor_without_checks(enforce_numbertype(C), map(to_meters, zero(SVector{3, Float64}))...)

# isnan
Base.isnan(x::Union{AbstractSatcomCoordinate, AbstractFieldValue}) = any(isnan, raw_properties(x))

# # isapprox
# function Base.isapprox(c1::C1, c2::C2; kwargs...) where {C1 <: CartesianPosition, C2 <: CartesianPosition}
#     basetype(C1) == basetype(C2) || throw(ArgumentError("Cannot compare coordinates of different types: $C1 and $C2"))
#     isapprox(raw_svector(c1), raw_svector(c2); kwargs...)
# end

# # Rand for LengthCartesian
# function Random.rand(rng::AbstractRNG, ::Random.SamplerType{L}) where L <: LengthCartesian
#     C = enforce_numbertype(L)
#     T = numbertype(C)
#     p = rand(rng, PointingVersor{T}) |> raw_svector
#     x, y, z = p * (1e3 * ((1 + rand(rng)) * u"m"))
#     constructor_without_checks(C, x, y, z)
# end

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
change_numbertype(::Type{T}, x::SVector{3}) where T <: Real = convert(SVector{3, T}, x)
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

# PlutoShowHelpers.show_namedtuple(c::LengthCartesian) = map(DisplayLength, raw_properties(c))

# function PlutoShowHelpers.show_namedtuple(c::AngleAngleDistance)
#     nt = getfields(c)
#     map(nt) do val
#         val isa Deg && return DualDisplayAngle(normalize_value(val))
#         val isa Met && return DisplayLength(normalize_value(val))
#     end
# end