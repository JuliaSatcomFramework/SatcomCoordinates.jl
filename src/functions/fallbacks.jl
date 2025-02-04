# Generic Tuple/SVector constructor for all LengthCartesian types
(::Type{P})(pt::Point{3, ValidDistance}) where P <: LengthCartesian = P(pt...)

# Generic 3-arg constructor for LengthCartesian types
function (::Type{P})(xyz::Vararg{ValidDistance, 3}) where P <: LengthCartesian
    PP = if has_numbertype(P) 
        P
    else
        NT = promote_type(map(numbertype, xyz)...)
        P{NT <: AbstractFloat ? NT : Float64}
    end
    any(isnan, xyz) && return constructor_without_checks(PP, NaN * u"m", NaN * u"m", NaN * u"m")
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
Base.isnan(coords::C) where C <: AbstractSatcomCoordinate = any(isnan, raw_nt(coords))

# isapprox
function Base.isapprox(c1::C1, c2::C2; kwargs...) where {C1 <: CartesianPosition, C2 <: CartesianPosition}
    basetype(C1) == basetype(C2) || throw(ArgumentError("Cannot compare coordinates of different types: $C1 and $C2"))
    isapprox(to_svector(c1), to_svector(c2); kwargs...)
end

# Rand for LengthCartesian
function Random.rand(rng::AbstractRNG, ::Random.SamplerType{L}) where L <: LengthCartesian
    C = enforce_numbertype(L)
    T = numbertype(C)
    p = rand(rng, PointingVersor{T}) |> to_svector
    x, y, z = p * (1e3 * ((1 + rand(rng)) * u"m"))
    constructor_without_checks(C, x, y, z)
end

function Base.convert(::Type{C1}, c::C2) where {C1 <: AbstractSatcomCoordinate, C2 <: AbstractSatcomCoordinate}
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
# Generic versions not on types of this package
numbertype(::Type{<:Quantity{T}}) where T  = T
numbertype(::Type{T}) where T <: Real = T
numbertype(::T) where T = numbertype(T)
numbertype(T::DataType) = error("The numbertype function is not implemented for type $T")
numbertype(::Type{<:AbstractArray{T}}) where T = T
# Implementation for our own types
numbertype(::Type{<:WithNumbertype{T}}) where T = T
numbertype(T::Type{<:WithNumbertype}) = error("The provided UnionAll type $T does not have the numbertype parameter specified")

change_numbertype(::Type, i::Identity) = i