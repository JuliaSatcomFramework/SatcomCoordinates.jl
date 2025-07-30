
BasicTypes.valuetype(::Type{<:AbstractSatcomCoordinate{<:Any, T}}) where T = T
BasicTypes.valuetype(::Type{<:AbstractSatcomCoordinate{<:Any}}) = Union{}

# This is the default implementation for CRSs that do not hold any coordinate within
BasicTypes.change_valuetype(::Type{<:AbstractFloat}, crs::AbstractCRS) = crs
function BasicTypes.change_valuetype(T::Type{<:AbstractFloat}, coord::Coordinate)
    newcrs = change_valuetype(T, crs(coord))
    newtup = map(T, tuplecoords(coord))
    return constructor_without_checks(basetype(typeof(coord)), newcrs, newtup)
end

#### Base ####
Base.isnan(coord::AbstractSatcomCoordinate) = any(isnan, tuplecoords(coord))
# Negation of a Coordinate
function Base.:(-)(c::AbstractSatcomCoordinate)
    base_crs = basecrs(c)
    if iscartesiancrs(base_crs)
        newtup = map(-, tuplecoords(c))
        return constructor_without_checks(basetype(typeof(c)), crs(coord), newtup)
    else
        throw(ArgumentError("The default implementation of `Base.(-)` for `AbstractSatcomCoordinate` is not available for the CRS which are not cartesian.\nThe CRS of the provided coordinate ($(typeof(crs(c)))) is not cartesian."))
    end
end

function Base.isapprox(c1::AbstractSatcomCoordinate, c2::AbstractSatcomCoordinate; kwargs...)
    if basetype(c1) !== basetype(c2)
        throw(ArgumentError("The default implementation of `Base.isapprox` for `AbstractSatcomCoordinate` only works between coordinates of the same base type (e.g. both being a subtype of `Coordinate`).\nThe two provided coordinates ($(basetype(c1)) and $(basetype(c2))) are not of the same base type."))
    end
    return raw_isapprox(basetype(c1), crs(c1), crs(c2), tuplecoords(c1), tuplecoords(c2); kwargs...)
end

"""
    raw_isapprox(C, crs1, crs2, coords1, coords2; kwargs...)

Low-level function that need to be extended for customizing the behavior of `Base.isapprox` for two instances `c1` and `c2` of the same base subtype of `AbstractSatcomCoordinate`

# Arguments
- `C::Type{<:AbstractSatcomCoordinate}`: The base type of the coordinate to be compared. E.g. `Coordinate`
- `crs1::AbstractCRS`: The CRS of the first coordinate
- `crs2::AbstractCRS`: The CRS of the second coordinate
- `coords1::NTuple{N, <:AbstractFloat}`: The raw coordinates of the first coordinate (i.e. the output of `tuplecoords(c1)`)
- `coords2::NTuple{N, <:AbstractFloat}`: The raw coordinates of the second coordinate (i.e. the output of `tuplecoords(c2)`)
- `kwargs...`: Additional keyword arguments to be passed to the `isapprox` function

This function has a default implementation for all comparisons between coordinates in the same CRS (i.e. `is_same_crs(crs1, crs2) == true`) which simply transforms the raw coordiantes in SVectors and calls `isapprox` on them.
"""
function raw_isapprox(::Type{C}, crs1::AbstractCRS, crs2::AbstractCRS, coords1::NTuple{N, <:AbstractFloat}, coords2::NTuple{N, <:AbstractFloat}; kwargs...) where {C <: AbstractSatcomCoordinate, N}
    if is_same_crs(crs1, crs2)
        return isapprox(SVector(coords1), SVector(coords2); kwargs...)
    else
        throw(ArgumentError("The default implementation of `Base.isapprox` for `AbstractSatcomCoordinate` only works between CRSs that are equivalent.\nThe two provided CRSs ($(crs1) and $(crs2)) are not equivalent and should be eventually covered by a new custom method of `SatcomCoordinates.raw_isapprox`."))
    end
end