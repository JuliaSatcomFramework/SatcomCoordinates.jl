"""
    upreferred(CRS::Type, unit::Unitful.Units)
    
Allow to customize the preferred unit on different types of CRSs. Defaults to `Unitful.upreferred(unit)`.

!!! note
    This is not the same function as `Unitful.upreferred` but just shares the same name as they basically have the same end goal. It is nonetheless redefined internally to `SatComCoordinates` to avoid polluting the methods of `Unitful.upreferred`.
"""
upreferred(unit::Unitful.Units) = Unitful.upreferred(unit)
upreferred(::Union{typeof(u"°"), typeof(u"rad")}) = u"rad"

add_unit(propunit::Unitful.Units, refunit::Unitful.Units, val::Real) = enforce_unit(refunit, val) |> propunit

remove_unit(propunit::Unitful.Units, refunit::Unitful.Units, val::Number) = enforce_unit(propunit, val) |> refunit |> ustrip

"""
    iscartesiancrs(C::Type{<:AbstractCRS})

Return `true` if the CRS `C` is a Cartesian CRS, `false` otherwise.

The default implementation assumes a CRS is cartesian if it has 3 properties and all of them have units of length.
"""
iscartesiancrs(C::Type{<:AbstractCRS}) = ncoords(C) == 3 && all(u -> u isa Unitful.LengthUnits, units(C))
iscartesiancrs(crs::AbstractCRS) = iscartesiancrs(typeof(crs))

isrootcrs(C::Type{<:AbstractCRS}) = !isderivedcrs(C)
isrootcrs(crs::AbstractCRS) = isrootcrs(typeof(crs))

function rootcrs(crs::AbstractCRS)
    isderivedcrs(crs) || return crs
    wrapped = wrappedcrs(crs)
    if isderivedcrs(wrapped)
        return rootcrs(wrapped)
    else
        return wrapped
    end
end
rootcrs(coord::FieldOrCoordinate) = rootcrs(crs(coord))

@inline ncoords(::Type{<:AbstractSatcomCoordinate{<:Any, <:Any, N}}) where N = N
@inline ncoords(::Type{CRS}) where CRS <: AbstractCRS = length(units(CRS))
@inline ncoords(obj::Union{AbstractCRS, FieldOrCoordinate}) = ncoords(typeof(obj))

@inline crstype(::Type{<:AbstractSatcomCoordinate{CRS}}) where CRS <: AbstractCRS = CRS
@inline crstype(::Type{CRS}) where CRS <: AbstractCRS = CRS
@inline crstype(::Type) = Union{}
@inline crstype(x::Union{AbstractCRS, AbstractSatcomCoordinate}) = crstype(typeof(x))

units(::CRS) where CRS <: AbstractCRS = units(CRS)
referenceunits(CRS::Type{<:AbstractCRS}) = map(upreferred, units(CRS))

crs(coord::AbstractSatcomCoordinate) = getfield(coord, :crs)
tuplecoords(coord::AbstractSatcomCoordinate) = getfield(coord, :tuplecoords)

function rawcoords(coord::AbstractSatcomCoordinate)
    CRS = crstype(coord)
    userunits = units(CRS)
    coords = tuplecoords(coord)
    return NamedTuple{keys(userunits)}(coords)
end

function coords(coord::AbstractSatcomCoordinate)
    CRS = crstype(coord)
    userunits = units(CRS)
    refunits = referenceunits(CRS)
    c = tuplecoords(coord)
    vals = ntuple(ncoords(CRS)) do i
        add_unit(userunits[i], refunits[i], c[i])
    end
    return NamedTuple{keys(userunits)}(vals)
end

"""
    wrappedcrs(crs::AbstractCRS)

Return the wrapped CRS from the provided `crs` if it exists, otherwise return the `crs` itself.

Custom CRSs which wrap a parent CRS (e.g. `SphericalCRS`) will either need to store the parent CRS in a field called `wrapped_crs`, or define a custom method for `wrappedcrs` which extracts the wrapped CRS.
"""
function wrappedcrs(crs::AbstractCRS)
    if isderivedcrs(crs)
        return getproperty_oftype(crs, AbstractCRS)
    else
        return crs
    end
end

"""
    cartesiancrs(crs::AbstractCRS)

Recursively traverse the CRSs wrapped by the provided `crs` until the first cartesian one (i.e. the first for which [`iscartesiancrs`](@ref) returns `true`) is found, and then return it.
"""
function cartesiancrs(crs::AbstractCRS)
    iscartesiancrs(crs) && return crs
    wrapped = wrappedcrs(crs)
    if iscartesiancrs(wrapped)
        return wrapped
    else
        return cartesiancrs(wrapped)
    end
end
cartesiancrs(coord::FieldOrCoordinate) = crs(coord) |> cartesiancrs


check_cartesian_wrapped(derived::Type{<:AbstractCRS}, wrapped::Type{<:AbstractCRS}) = iscartesiancrs(wrapped) || throw(ArgumentError("CRSs of type $(basetype(derived)) must be defined over a Cartesian CRS, while the provided CRS ($(basetype(wrapped))) is not a Cartesian one."))
check_cartesian_wrapped(derived::Type{<:AbstractCRS}, wrapped::AbstractCRS) = check_cartesian_wrapped(derived, typeof(wrapped))



defaultcrs(::Type{<:AbstractSatcomCoordinate{CRS}}) where CRS <: AbstractCRS = CRS()
defaultcrs(::Type{<:AbstractSatcomCoordinate{<:Any}}) = Cartesian()
defaultcrs(::Type{Pointing}) = ThetaPhi()

default_wrappedcrs(::Type{<:AbstractCRS}) = Cartesian()


function change_crs(crsₒ::AbstractCRS, coord::AbstractSatcomCoordinate)
    tup = transform_tuplecoords(crsₒ, crs(coord), tuplecoords(coord))
    return constructor_without_checks(basetype(typeof(coord)), crsₒ, tup)
end
change_crs(::CRS, coord::AbstractSatcomCoordinate{CRS}) where CRS = coord

function transform_tuplecoords(crsₒ::AbstractCRS, crsᵢ::AbstractCRS, ::Any)
    throw(ArgumentError("No conversion is defined to go from an input CRS of type `$(typeof(crsᵢ))` to an output CRS of type `$(typeof(crsₒ))`"))
end


"""
    isderivedcrs(C::Type{<:AbstractCRS})
    isderivedcrs(crs::AbstractCRS)

Checks whether a given `crs` (or `CRS` type) is derived from another CRS type or no.

!!! note
    The default implementation simply checks if the CRS type has a field which subtypes `AbstractCRS`.
"""
function isderivedcrs(C::Type{<:AbstractCRS})
    return any(p -> p <: AbstractCRS, fieldtypes(C))
end
isderivedcrs(crs::AbstractCRS) = isderivedcrs(typeof(crs))