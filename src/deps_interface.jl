
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
