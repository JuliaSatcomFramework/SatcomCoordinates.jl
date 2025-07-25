struct Position{CRS <: AbstractCRS, T} <: AbstractSatcomCoordinate{CRS, T, 3}
    crs::CRS
    tuplecoords::NTuple{3, T}

    BasicTypes.constructor_without_checks(::Type{Position{CRS, T}}, crs::CRS, tuplecoords::NTuple{3, T}) where {CRS <: AbstractCRS, T} = new{CRS, T}(crs, tuplecoords)
end
(C::Type{<:AbstractSatcomCoordinate})(args::Vararg{Any, N}) where {N} = create_coordinate(C, args...)

create_coordinate(C::Type{<:AbstractSatcomCoordinate}, args::Point{M, Number}) where {M} = create_coordinate(C, args...)
create_coordinate(C::Type{<:AbstractSatcomCoordinate}, crs::AbstractCRS, args::Point{M, Number}) where {M} = create_coordinate(C, crs, args...)
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
    T = if CT == Union{}
        common_valuetype(AbstractFloat, Float64, coords...)
    else
        CT
    end
    tup = preprocess_input_coords(CRS, T, coords)
    return process_unitless_coords(C, crs, tup)
end

"""
    preprocess_input_coords(CRS::Type{<:AbstractCRS}, T::Type{<:AbstractFloat}, coords::Point{N, Any}) where N

This function take input coordinates and process them by eventually removing units they come with (ensuring consistency with the units expected from a CRS) and converting them to the specific machine precision specified by the type parameter `T`.
"""
function preprocess_input_coords(CRS::Type{<:AbstractCRS}, T::Type{<:AbstractFloat}, coords::Point{N, Any}) where {N}
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
    process_unitless_coords(::Type{C}, crs::AbstractCRS, coords::NTuple{<:Any, T}) where {C <: FieldOrCoordinate, T}

This function is the last step in the pipeline for creating a coordinate as part of the `create_coordinate` function.
    
By default it simply calls the constructor of the coordinate type with the provided CRS and coordinates without checks.

When specific processing on the unitless values is required for a particular Coordinate type `C` or crs type, a method to this function should be added, and it should generated a coordinate of type `C` with a CRS of type `typeof(crs)` and machine precision `T`.
"""
function process_unitless_coords(::Type{C}, crs::AbstractCRS, coords::NTuple{<:Any, T}) where {C <: FieldOrCoordinate, T}
    CT = basetype(C){typeof(crs), T}
    constructor_without_checks(CT, crs, coords)
end

"""
    wrappedcrs(crs::AbstractCRS)

Return the wrapped CRS from the provided `crs` if it exists, otherwise return the `crs` itself.

Custom CRSs which wrap a parent CRS (e.g. `SphericalCRS`) will either need to store the parent CRS in a field called `wrapped_crs`, or define a custom method for `wrappedcrs` which extracts the wrapped CRS.
"""
wrappedcrs(crs::AbstractCRS) = hasfield(typeof(crs), :wrapped_crs) ? getfield(crs, :wrapped_crs) : crs

default_wrappedcrs(::Type{<:AbstractCRS}) = Cartesian()

"""
    cartesiancrs(crs::AbstractCRS)

Recursively traverse the CRSs wrapped by the provided `crs` until the first cartesian one (i.e. subtyping `AbstractCartesianCRS`) is found, and then return it.
"""
function cartesiancrs(crs::AbstractCRS)
    parent = wrappedcrs(crs)
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
struct Raw{CRS <: AbstractCRS, C <: FieldOrCoordinate{CRS}} <: FieldOrCoordinate{CRS}
    wrapped::C
end
Raw(c::FieldOrCoordinate{CRS}) where {CRS} = Raw{CRS, typeof(c)}(c)

@inline wrapped(r::Raw) = getfield(r, :wrapped)
@inline Base.propertynames(r::Raw) = propertynames(wrapped(r))
@inline coords(r::Raw) = rawcoords(wrapped(r))
@inline crs(r::Raw) = crs(wrapped(r))



struct Pointing{CRS <: AbstractPointingCRS, T} <: AbstractSatcomCoordinate{CRS, T, 2}
    crs::CRS
    tuplecoords::NTuple{2, T}

    BasicTypes.constructor_without_checks(::Type{Pointing{CRS, T}}, crs::CRS, tuplecoords::NTuple{2, T}) where {CRS <: AbstractCRS, T} = new{CRS, T}(crs, tuplecoords)
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