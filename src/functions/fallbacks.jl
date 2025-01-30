# Generic Tuple/SVector constructor for all Cartesian types
(::Type{P})(pt::Point{3, ValidDistance}) where P <: LengthCartesian = P(pt...)

Base.isnan(coords::C) where C <: AbstractSatcomCoordinate = any(isnan, raw_nt(coords))
function Base.isapprox(c1::C1, c2::C2; kwargs...) where {C1 <: CartesianPosition, C2 <: CartesianPosition}
    basetype(C1) == basetype(C2) || throw(ArgumentError("Cannot compare coordinates of different types: $C1 and $C2"))
    isapprox(to_svector(c1), to_svector(c2); kwargs...)
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
