"""
    Coordinate{CRS <: AbstractCRS, T, N} <: AbstractSatcomCoordinate{CRS, T, N}

A generic coordinate type, which wraps a CRS and a tuple of coordinates.

The interpretation of the coordinate depends on the specific CRS it is defined on (e.g. a Coordinate over a PointingCRS can be considered a Pointing direction)

The type parameter `CRS` is the CRS type, `T` is the type of the coordinates, and `N` is the number of coordinates.

The type parameter `CRS` is a subtype of `AbstractCRS`, and the type parameter `T` is a subtype of `AbstractFloat`.

# Constructors
    Coordinate(crs::AbstractCRS, coords...)
    (crs::AbstractCRS)(coords...)

Coordinates can be constructed directly with the `Coordinate` constructor by providing a CRS instance as first argument and the specific numerical coordinates (either as tuple/svector or as separate values) as remaining argument[s]

Alternatively (and usually easier) an instance of a specific CRS can be directly used with the numerical coordinates to construct a `Coordinate` instance

# Examples
```jldoctest
julia> using SatcomCoordinates

julia> cartcrs = Cartesian();

julia> cartcrs(1, 2, 3)
Coordinate{Cartesian}:
  x = 1.0 m
  y = 2.0 m
  z = 3.0 m

julia> cartcrs((1,2,3)) == Coordinate(cartcrs, 1, 2, 3)
true
```

# Extended Help

The coordinates over the specific CRS are stored internally as a plain `NTuple{N, T}` (where `T <: AbstractFloat` is currently enforced during construction) which holds the raw coordinates (i.e. without unit and transformed to corresponding SI unit (for angles we transform to radians). This means that for example if a specific CRS has the unit of `u"km"`, the raw values stored internally are the numerical value in meters)

The constructor basically goes over the following 3 steps:
- Eventually strip units and normalize to unitless SI floating point values using the `preprocess_input_coords` function.
  - This function should not need to be customized for custom CRSs and only operates on the specific units associated to each properties specified with the `@define_properties` macro.
- Perform additional checks and manipulation on the raw coordinates based on the specific CRS instance provided to the constructor, using the `process_unitless_coords` function.
  - Not all custom CRSs require special processing and the default method for the `process_unitless_coords` function simply returns the input tuple as is. An example of CRSs that need to do some further processing are the concrete subtypes of `AbstractPointingCRS` which wraps the angles to always have them within the range `[-π, π]`
"""
struct Coordinate{CRS <: AbstractCRS, T, N} <: AbstractSatcomCoordinate{CRS, T, N}
    crs::CRS
    tuplecoords::NTuple{N, T}

    function BasicTypes.constructor_without_checks(::Type{Coordinate}, crs::CRS, tuplecoords::NTuple{N, T}) where {CRS <: AbstractCRS, T <: AbstractFloat, N} 
        return new{CRS, T, N}(crs, tuplecoords)
    end
end

# This just forwards to the next
Coordinate(crs::AbstractCRS, coords::Point{<:Any, Number}) = Coordinate(crs, coords...)
# This is the main constructor
function Coordinate(crs::AbstractCRS, coords::Vararg{Number, N}) where {N}
    N == ncoords(crs) || _dimension_mismatch_error(crs, N)
    # We check that if a crs was provided in the coordinate type signature, that it matches the provided crs instance
    CRS = typeof(crs)
    T = common_valuetype(AbstractFloat, Float64, coords...)
    tup = preprocess_input_coords(CRS, T, coords)
    raw = process_unitless_coords(Coordinate, crs, tup)
    return constructor_without_checks(Coordinate, crs, raw)
end

const Pointing{CRS <: AbstractPointingCRS, T, N} = Coordinate{CRS, T, N}

"""
    preprocess_input_coords(CRS::Type{<:AbstractCRS}, T::Type{<:AbstractFloat}, coords::Point{N, Any}) where N

This function take input coordinates and process them by eventually removing units they come with (ensuring consistency with the units expected from a CRS) and converting them to the specific machine precision specified by the type parameter `T`.
"""
function preprocess_input_coords(CRS::Type{<:AbstractCRS}, T::Type{<:AbstractFloat}, coords::Point{N, Any}) where {N}
    userunits = units(CRS)
    refunits = referenceunits(CRS)
    N == ncoords(CRS) || _dimension_mismatch_error(crs, N)
    tup = ntuple(N) do i
        unit = userunits[i]
        refunit = refunits[i]
        val = coords[i]
        remove_unit(unit, refunit, val) |> T
    end
    return tup
end


"""
    process_unitless_coords(::Type{C}, crs::AbstractCRS, coords::NTuple{<:Any, T}) where {C <: FieldOrCoordinate, T}

This function is the last step in the pipeline for creating a coordinate as part of the `create_coordinate` function.

It takes as input the `NTuple` already stripped of eventual units (and normalized to the reference/preferred unit before being stripped) and should just do final checks on the inputs and return an eventualy modified NTuple (e.g. wrap angles in radians if beyond [-π, π]), which will be then used to create the coordinate instance via the `constructor_without_checks` function.
    
The default method for this function simply returns the input `NTuple` as is. Custom CRSs that require specific checks or modification of the unitless inputs should add a method to this function.
"""
function process_unitless_coords(::Type{C}, crs::AbstractCRS, coords::NTuple{<:Any, T}) where {C <: FieldOrCoordinate, T}
    return coords
end


@inline Base.propertynames(coord::AbstractSatcomCoordinate) = propertynames(units(crs(coord)))

@inline Base.@constprop :aggressive function Base.getproperty(obj::FieldOrCoordinate, s::Symbol)
    props = coords(obj)
    CRS = crs(obj) |> typeof
    nm = resolve_property(CRS, s)::Symbol
    nm === :__could_not_resolve_property__ && throw(ArgumentError("The requested property name `:$(s)` is not a valid property for a coordinate over a CRS of type `$CRS`"))
    getproperty(props, nm)
end

# This is to automatically construct a coordinate instance when trying to feed coords to a CRS constructor

_dimension_mismatch_error(crs::AbstractCRS, N) = throw(DimensionMismatch("The number of coordinates provided ($(N)) does not match the number of coordinates expected by CRS of type $(typeof(crs)) ($(ncoords(crs)))"))

_no_fastcoord_error(CRS::Type{<:AbstractCRS}) = throw(ArgumentError("The CRS type $CRS does not have a custom implementation of a no-argument constructor.\n It can not be used for generating a coordinate by simply using the typename ($(CRS)) as on values."))

for T in (Vararg{Number}, Point{N, Number} where N)
    @eval function (CRS::Type{<:AbstractCRS})(coords::$T{N}) where {N}
        if N === 0
            _no_fastcoord_error(CRS)
        end
        return CRS()(coords...)
    end

    # These are the methods that take an instance of a CRS and construct a coordinate with it
    @eval function (crs::AbstractCRS)(coords::$T{N}) where {N}
        N == ncoords(crs) || _dimension_mismatch_error(crs, N)
        return Coordinate(crs, coords)
    end
end

#### Show Methods ####
const SHOW_TYPES = Union{AbstractCRS, FieldOrCoordinate, AbstractCRSTransform}

# Basic overloads
Base.show(io::IO, mime::MIME"text/plain", x::SHOW_TYPES) = show(io, mime, DefaultShowOverload(x))
Base.show(io::IO, mime::MIME"text/html", x::SHOW_TYPES) = show(io, mime, DefaultShowOverload(x))
Base.show(io::IO, x::SHOW_TYPES) = show(io, DefaultShowOverload(x))

function _coordstring(c::AbstractSatcomCoordinate)
    if crs(c) isa AbstractPointingCRS
        "Pointing"
    else
        "Coordinate"
    end
end

PlutoShowHelpers.shortname(c::AbstractCRS) = string(basetype(c |> typeof))
function PlutoShowHelpers.repl_summary(c::AbstractCRS) 
    if hascrstrait(linkedcrs, c)
        linked = getcrs(linkedcrs, c)
        return PlutoShowHelpers.shortname(c) * "{" * PlutoShowHelpers.shortname(linked) * "}"
    else
        return Base.summary(c)
    end
end

PlutoShowHelpers.shortname(x::AbstractSatcomCoordinate) = _coordstring(x) * "{" * PlutoShowHelpers.shortname(crs(x)) * "}"

PlutoShowHelpers.repl_summary(p::AbstractSatcomCoordinate) = _coordstring(p) * "{" * PlutoShowHelpers.repl_summary(crs(p)) * "}"

PlutoShowHelpers.show_namedtuple(c::AbstractSatcomCoordinate) = getproperties(c)

#### Random.rand #####
function Random.rand(rng::AbstractRNG, s::Random.SamplerTrivial{CRS}) where {CRS <: AbstractCRS}
    crs = s[]
    T = common_valuetype(AbstractFloat, Float64, crs)
    tup = rand_tuplecoords(rng, crs, T)
    return constructor_without_checks(Coordinate, crs, tup)
end