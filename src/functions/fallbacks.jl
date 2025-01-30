# Generic Tuple/SVector constructor for all Cartesian types
(::Type{P})(pt::Point{3, ValidDistance}) where P <: LengthCartesian = P(pt...)

Base.isnan(coords::C) where C <: AbstractSatcomCoordinate = any(isnan, raw_nt(coords))
function Base.isapprox(c1::C1, c2::C2; kwargs...) where {C1 <: CartesianPosition, C2 <: CartesianPosition}
    basetype(C1) == basetype(C2) || throw(ArgumentError("Cannot compare coordinates of different types: $C1 and $C2"))
    isapprox(to_svector(c1), to_svector(c2); kwargs...)
end
