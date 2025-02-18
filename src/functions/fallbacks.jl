# Generic NaN constructor for all SatcomCoordinate types
(::Type{C})(::Val{NaN}) where C <: AbstractSatcomCoordinate = constructor_without_checks(enforce_numbertype(C), NaN, NaN, NaN)
(::Type{C})(::Val{NaN}) where C <: LengthCartesian = constructor_without_checks(enforce_numbertype(C), NaN * u"m", NaN * u"m", NaN * u"m")
(::Type{C})(::Val{NaN}) where C <: AngleAngleDistance = constructor_without_checks(enforce_numbertype(C), NaN * u"°", NaN * u"°", NaN * u"m")

# Generic Tuple/SVector constructor for all LengthCartesian types
(::Type{P})(pt::Point{3, ValidDistance}) where P <: LengthCartesian = P(pt...)

# Generic 3-arg constructor for LengthCartesian types
function (::Type{P})(xyz::Vararg{ValidDistance, 3}) where P <: LengthCartesian
    PP = enforce_numbertype(P, default_numbertype(xyz...))
    any(isnan, xyz) && return PP(Val{NaN}())
    x, y, z = map(to_meters, xyz)
    constructor_without_checks(PP, x, y, z)
end

# Addition, subtraction and sign inversion
Base.:(-)(c::C) where C <: CartesianPosition = constructor_without_checks(C, -c.x, -c.y, -c.z)
function Base.:(+)(c1::C1, c2::C2) where {C1 <: CartesianPosition, C2 <: CartesianPosition} 
    C = basetype(C1)
    C == basetype(C2) || throw(ArgumentError("Cannot add coordinates of different types: $C1 and $C2"))
    T = promote_type(numbertype(C1), numbertype(C2))
    constructor_without_checks(C{T}, c1.x + c2.x, c1.y + c2.y, c1.z + c2.z)
end
Base.:(-)(c1::C1, c2::C2) where {C1 <: CartesianPosition, C2 <: CartesianPosition} = c1 + (-c2)

# zero
Base.zero(::Type{C}) where C <: CartesianPosition = constructor_without_checks(enforce_numbertype(C), map(to_meters, zero(SVector{3, Float64}))...)

# isnan
Base.isnan(x::Union{AbstractSatcomCoordinate, AbstractFieldValue}) = any(isnan, normalized_properties(x))

# isapprox
function Base.isapprox(c1::C1, c2::C2; kwargs...) where {C1 <: CartesianPosition, C2 <: CartesianPosition}
    basetype(C1) == basetype(C2) || throw(ArgumentError("Cannot compare coordinates of different types: $C1 and $C2"))
    isapprox(normalized_svector(c1), normalized_svector(c2); kwargs...)
end

# Rand for LengthCartesian
function Random.rand(rng::AbstractRNG, ::Random.SamplerType{L}) where L <: LengthCartesian
    C = enforce_numbertype(L)
    T = numbertype(C)
    p = rand(rng, PointingVersor{T}) |> normalized_svector
    x, y, z = p * (1e3 * ((1 + rand(rng)) * u"m"))
    constructor_without_checks(C, x, y, z)
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
    vals = @inline getfields(c)
    return constructor_without_checks(C1, vals...)
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

# Base.getproperty fallback with generated function (to have faster getproperty)
@generated function Base.getproperty(c::Union{AbstractSatcomCoordinate, AbstractFieldValue}, s::Symbol)
    aliases = property_aliases(c)
    block = Expr(:block)
    args = block.args
    push!(args, :(nt = raw_properties(c)))
    push!(args, :(s in $(fieldnames(c)) && return getfield(c, s)))
    for (k, v) in pairs(aliases)
        push!(args, :(s in $v && return getproperty(nt, $(QuoteNode(k)))))
    end
    push!(args, :(throw(ArgumentError("Objects of type `$(typeof(c))` do not have a property called `$s`"))))
    return block
end

# Overload show method
# Basic overloads
Base.show(io::IO, mime::MIME"text/plain", x::WithNumbertype) = show(io, mime, DefaultShowOverload(x))
Base.show(io::IO, mime::MIME"text/html", x::WithNumbertype) = show(io, mime, DefaultShowOverload(x))
Base.show(io::IO, x::WithNumbertype) = show(io, DefaultShowOverload(x))

PlutoShowHelpers.shortname(x::AbstractSatcomCoordinate) = x |> typeof |> basetype |> nameof |> string

PlutoShowHelpers.repl_summary(p::AbstractSatcomCoordinate) = shortname(p) * " Coordinate"

PlutoShowHelpers.show_namedtuple(c::LengthCartesian) = map(DisplayLength, normalized_properties(c))

function PlutoShowHelpers.show_namedtuple(c::AngleAngleDistance)
    nt = getfields(c)
    map(nt) do val
        val isa Deg && return DualDisplayAngle(normalize_value(val))
        val isa Met && return DisplayLength(normalize_value(val))
    end
end