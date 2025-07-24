struct Position{CRS <: AbstractCRS, T} <: AbstractSatcomCoordinate{CRS, T, 3}
    crs::CRS
    tuplecoords::NTuple{3, T}

    BasicTypes.constructor_without_checks(::Type{Position{CRS, T}}, crs::CRS, tuplecoords::NTuple{3, T}) where {CRS <: AbstractCRS, T} = new{CRS, T}(crs, tuplecoords)
end
function Position(crs::CRS, tuplecoords::NTuple{3, T}) where {CRS <: AbstractCRS, T <: AbstractFloat} 
    constructor_without_checks(Position{CRS, T}, crs, tuplecoords)
end
(C::Type{<:AbstractSatcomCoordinate})(args::Vararg{Any, N}) where N = create_coordinate(C, args...)

bypass_bottom(::typeof(Union{}), ::typeof(Union{})) = throw(ArgumentError("You can't have a default type which is Union{}"))
bypass_bottom(::Type, ::typeof(Union{})) = throw(ArgumentError("You can't have a default type which is Union{}"))
@inline bypass_bottom(::typeof(Union{}), T::Type) = T
@inline bypass_bottom(T::Type, ::Type) = T

create_coordinate(C::Type{<:AbstractSatcomCoordinate}, args::Point{M, Number}) where M = create_coordinate(C, args...)
create_coordinate(C::Type{<:AbstractSatcomCoordinate}, crs::AbstractCRS, args::Point{M, Number}) where M = create_coordinate(C, crs, args...)
function create_coordinate(C::Type{<:AbstractSatcomCoordinate{<:Any, <:Any, N}}, coords::Vararg{Number, M}) where {N, M}
    return create_coordinate(C, defaultcrs(C), coords...)
end
function create_coordinate(C::Type{<:AbstractSatcomCoordinate{<:Any, <:Any, N}}, crs::AbstractCRS, coords::Vararg{Number, M}) where {N, M}
    N == M || throw(DimensionMismatch("The number of coordinates provided ($(M)) does not match the number of coordinates expected by the coordinate type $C ($(N))"))
    # We check that if a crs was provided in the coordinate type signature, that it matches the provided crs instance
    CRS = typeof(crs)
    if crstype(C) !== Union{}
        crstype(C) == CRS || throw(ArgumentError("The provided crs does not match the crs type signature of the coordinate type $C"))
    end
    CT = valuetype(C)
    T = bypass_bottom(CT, common_valuetype(AbstractFloat, Float64, coords...))
    tup = preprocess_input_coords(CRS, T, coords)
    return constructorof(C)(crs, tup)
end

"""
    preprocess_input_coords(CRS::Type{<:AbstractCRS}, T::Type{<:AbstractFloat}, coords::Point{N, Any}) where N

This function take input coordinates and process them by eventually removing units they come with (ensuring consistency with the units expected from a CRS) and converting them to the specific machine precision specified by the type parameter `T`.
"""
function preprocess_input_coords(CRS::Type{<:AbstractCRS}, T::Type{<:AbstractFloat}, coords::Point{N, Any}) where N
    units = coords_units(CRS)
    N == length(units) || throw(DimensionMismatch("The number of coordinates provided ($(N)) does not match the number of coordinates expected by type $C ($(N))"))
    tup = ntuple(length(coords)) do i
        unit = units[i]
        val = coords[i]
        enforce_unitless(unit, val) |> T
    end
    return tup
end

@inline ncoords(::Type{<:AbstractSatcomCoordinate{<:Any, <:Any, N}}) where N = N

@inline crstype(::Type{<:AbstractSatcomCoordinate{CRS}}) where CRS <: AbstractCRS = CRS
@inline crstype(::Type{CRS}) where CRS <: AbstractCRS = CRS
@inline crstype(::Type) = Union{}
@inline crstype(x::Union{AbstractCRS, AbstractSatcomCoordinate}) = crstype(typeof(x))

BasicTypes.valuetype(::Type{<:AbstractSatcomCoordinate{<:Any, T}}) where T = T
BasicTypes.valuetype(::Type{<:AbstractSatcomCoordinate{<:Any}}) = Union{}

coords_units(::Type{<:AbstractCartesianCRS}) = (; x = u"m", y = u"m", z = u"m")
coords_units(::CRS) where CRS <: AbstractCRS = coords_units(CRS)

crs(coord::AbstractSatcomCoordinate) = getfield(coord, :crs)
tuplecoords(coord::AbstractSatcomCoordinate) = getfield(coord, :tuplecoords)

function rawcoords(coord::AbstractSatcomCoordinate)
    CRS = crstype(coord)
    units = coords_units(CRS)
    coords = tuplecoords(coord)
    return NamedTuple{keys(units)}(coords)
end

function coords(coord::AbstractSatcomCoordinate)
    CRS = crstype(coord)
    units = coords_units(CRS)
    c = tuplecoords(coord)
    vals = ntuple(length(c)) do i
        enforce_unit(units[i], c[i])
    end
    return NamedTuple{keys(units)}(vals)
end

@inline Base.propertynames(coord::AbstractSatcomCoordinate) = propertynames(coords_units(crs(coord)))

"""
    Cartesian <: AbstractCartesianCRS

Generic Cartesian CRS, for use in cases that do not require any specific identification of a CRS/Position
"""
struct Cartesian <: AbstractCartesianCRS end

struct SphericalCRS{CRS <: PointingCRS} <: AbstractCRS 
    parent_crs::CRS
end
SphericalCRS() = SphericalCRS(PointingCRS())

coords_units(S::Type{<:SphericalCRS}) = (coords_units(pointingtype(S))..., r = u"m")
Base.@constprop :aggressive function resolve_property(S::Type{<:SphericalCRS}, propname::Symbol)
    if propname in (:r, :distance, :range)
        return :r
    else
        return resolve_property(pointingtype(S), propname)
    end
end

pointingtype(::Type{<:PointingCRS{<:Any, P}}) where P = P
pointingtype(::Type{SphericalCRS{PCRS}}) where PCRS <: PointingCRS = pointingtype(PCRS)
pointingtype(crs::AbstractCRS) = pointingtype(typeof(crs))

struct Pointing{CRS <: PointingCRS, T} <: AbstractSatcomCoordinate{CRS, T, 2}
    crs::CRS
    tuplecoords::NTuple{2, T}

    BasicTypes.constructor_without_checks(::Type{Pointing{CRS, T}}, crs::CRS, tuplecoords::NTuple{2, T}) where {CRS <: AbstractCRS, T} = new{CRS, T}(crs, tuplecoords)
end
function Pointing(crs::CRS, coords::NTuple{2, T}) where {CRS <: PointingCRS, T <: AbstractFloat} 
    PT = pointingtype(CRS)
    tup = process_pointing_coords(PT, coords)
    return constructor_without_checks(Pointing{CRS, T}, crs, tup)
end

defaultcrs(::Type{<:AbstractSatcomCoordinate{CRS}}) where CRS <: AbstractCRS = CRS()
defaultcrs(::Type{<:AbstractSatcomCoordinate{<:Any}}) = Cartesian()
defaultcrs(::Type{Pointing}) = PointingCRS()

@inline Base.@constprop :aggressive function Base.getproperty(coord::AbstractSatcomCoordinate, s::Symbol)
    props = coords(coord)
    CRS = crs(coord) |> typeof
    getproperty(props, resolve_property(CRS, s))
end