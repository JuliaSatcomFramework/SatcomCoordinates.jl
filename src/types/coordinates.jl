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
    userunits = units(CRS)
    refunits = referenceunits(CRS)
    N == ncoords(CRS) || throw(DimensionMismatch("The number of coordinates provided ($(N)) does not match the number of coordinates expected by CRS of type $CRS ($(ncoords(CRS)))"))
    tup = ntuple(N) do i
        unit = userunits[i]
        refunit = refunits[i]
        val = coords[i]
        remove_unit(unit, refunit, val) |> T
    end
    return tup
end

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

@inline ncoords(::Type{<:AbstractSatcomCoordinate{<:Any, <:Any, N}}) where N = N
@inline ncoords(::Type{CRS}) where CRS <: AbstractCRS = length(units(CRS))
@inline ncoords(obj::Union{AbstractCRS, FieldOrCoordinate}) = ncoords(typeof(obj))

@inline crstype(::Type{<:AbstractSatcomCoordinate{CRS}}) where CRS <: AbstractCRS = CRS
@inline crstype(::Type{CRS}) where CRS <: AbstractCRS = CRS
@inline crstype(::Type) = Union{}
@inline crstype(x::Union{AbstractCRS, AbstractSatcomCoordinate}) = crstype(typeof(x))

BasicTypes.valuetype(::Type{<:AbstractSatcomCoordinate{<:Any, T}}) where T = T
BasicTypes.valuetype(::Type{<:AbstractSatcomCoordinate{<:Any}}) = Union{}

units(::CRS) where CRS <: AbstractCRS = units(CRS)
referenceunits(CRS::Type{<:AbstractCRS}) = map(upreferred, units(CRS))

@define_properties AbstractCartesianCRS [
    x => u"m"
    y => u"m"
    z => u"m"
]

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
    parentcrs(crs::AbstractCRS)

Return the parent CRS of the provided `crs` if it exists, otherwise return the `crs` itself.

Custom CRSs which wrap a parent CRS (e.g. `SphericalCRS`) will either need to store the parent CRS in a field called `parent_crs`, or define a custom method for `parentcrs` which extracts the wrapped CRS.
"""
parentcrs(crs::AbstractCRS) = hasfield(typeof(crs), :parent_crs) ? getfield(crs, :parent_crs) : crs

"""
    cartesiancrs(crs::AbstractCRS)

Recursively traverse the CRSs wrapped by the provided `crs` until the first cartesian one (i.e. subtyping `AbstractCartesianCRS`) is found, and then return it.
"""
function cartesiancrs(crs::AbstractCRS)
    parent = parentcrs(crs)
    if parent isa AbstractCartesianCRS
        return parent
    else
        return cartesiancrs(parent)
    end
end

@inline Base.propertynames(coord::AbstractSatcomCoordinate) = propertynames(units(crs(coord)))

"""
    Raw{C <: FieldOrCoordinate} <: FieldOrCoordinate

Structure that is only used to wrap a `FieldOrCoordinate` object and allow to access its raw values (i.e. normalized and without units) directly via `Base.getproperty`.

# Example
```julia
using SatcomCoordinates

# Define our custom Cartesian CRS
struct CustomKM <: AbstractCartesianCRS end

# We specify that this has x,y,z properties which have default unit of km (i.e. plain numbers are interpreted as km). The raw coordinates (i.e. how they are stored internally in the coordinate instances) are actually floating point values represented in meters (as that is the SI unit for length)
@define_properties CustomKM [
    x => u"km"
    y => u"km"
    z => u"km"
]

# Create a position in the custom CRS at x = 1km, y = 2km, z = 3km
pkm = Position(CartesianKM(), 1,2,3)

# Normal property access 
pkm.x === 1.0u"km" # true

# If you want to directly access the raw unitless data (e.g. inside of hot loops), you can wrap the coordinate in `Raw`
(; y) = Raw(pkm) # This uses the julia desctructuring synthax that relies on `Base.getproperty`

y === 2000.0 # true
```
"""
struct Raw{C <: FieldOrCoordinate} <: FieldOrCoordinate
    wrapped::C
end

@inline wrapped(r::Raw) = getfield(r, :wrapped)
@inline Base.propertynames(r::Raw) = propertynames(wrapped(r))
@inline coords(r::Raw) = rawcoords(wrapped(r))
@inline crs(r::Raw) = crs(wrapped(r))


"""
    Cartesian <: AbstractCartesianCRS

Generic Cartesian CRS, for use in cases that do not require any specific identification of a CRS/Position
"""
struct Cartesian <: AbstractCartesianCRS end

struct SphericalCRS{CRS <: AbstractPointingType} <: AbstractCRS 
    parent_crs::CRS
end
SphericalCRS() = SphericalCRS(ThetaPhi())

@define_properties SphericalCRS [
    pointingtype(_)... # This is a special synthax for the macro, saying that it should put here all the properties of the the `CRS` obtained by calling `pointingtype(CRS::Type{<:SphericalCRS})`
    r => u"m" => (:distance, :range) # r as primary property name, u"m" as unit for `r` and `distance` and `range` as aliases for this property
]

pointingtype(P::Type{<:AbstractPointingType}) = P
pointingtype(::Type{SphericalCRS{P}}) where P <: AbstractPointingType = P
pointingtype(crs::AbstractCRS) = pointingtype(typeof(crs))

struct Pointing{CRS <: AbstractPointingType, T} <: AbstractSatcomCoordinate{CRS, T, 2}
    crs::CRS
    tuplecoords::NTuple{2, T}

    BasicTypes.constructor_without_checks(::Type{Pointing{CRS, T}}, crs::CRS, tuplecoords::NTuple{2, T}) where {CRS <: AbstractCRS, T} = new{CRS, T}(crs, tuplecoords)
end
function Pointing(crs::CRS, coords::NTuple{2, T}) where {CRS <: AbstractPointingType, T <: AbstractFloat} 
    PT = pointingtype(CRS)
    tup = process_pointing_coords(PT, coords)
    return constructor_without_checks(Pointing{CRS, T}, crs, tup)
end

defaultcrs(::Type{<:AbstractSatcomCoordinate{CRS}}) where CRS <: AbstractCRS = CRS()
defaultcrs(::Type{<:AbstractSatcomCoordinate{<:Any}}) = Cartesian()
defaultcrs(::Type{Pointing}) = ThetaPhi()

@inline Base.@constprop :aggressive function Base.getproperty(obj::FieldOrCoordinate, s::Symbol)
    props = coords(obj)
    CRS = crs(obj) |> typeof
    nm = resolve_property(CRS, s)::Symbol
    nm === :__could_not_resolve_property__ && throw(ArgumentError("The requested property name `:$(s)` is not a valid property for a coordinate over a CRS of type `$CRS`"))
    getproperty(props, nm)
end


function change_crs(crsₒ::AbstractCRS, coord::AbstractSatcomCoordinate)
    return change_crs(crsₒ, crs(coord), tuplecoords(coord))
end
change_crs(::CRS, coord::AbstractSatcomCoordinate{CRS}) where CRS = coord

function change_crs(crsₒ::AbstractCRS, crsᵢ::AbstractCRS, tup)
    throw(ArgumentError("No conversion is defined to go from an input CRS of type `$(typeof(crsᵢ))` to an output CRS of type `$(typeof(crsₒ))`"))
end