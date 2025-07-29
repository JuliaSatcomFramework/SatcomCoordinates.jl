"""
    Coordinate{CRS <: AbstractCRS, T, N} <: AbstractSatcomCoordinate{CRS, T, N}

A generic coordinate type, which wraps a CRS and a tuple of coordinates.

The interpretation of the coordinate depends on the specific CRS it is defined on (e.g. a Coordinate over a PointingCRS can be considered a Pointing direction)

The type parameter `CRS` is the CRS type, `T` is the type of the coordinates, and `N` is the number of coordinates.

The type parameter `CRS` is a subtype of `AbstractCRS`, and the type parameter `T` is a subtype of `AbstractFloat`.

The constructor internally calls the `create_coordinate` function, which is the main entry point for creating a coordinate instance.

This in turn relies on the `preprocess_input_coords` and `process_unitless_coords` functions, which are the main entry points for processing the input coordinates and unitless coordinates respectively.
Custom CRSs can add more specific methods to either of these functions, but it is usually only necessary (and not even always) to add a custom method to `process_unitless_coords` to achieve the desired behavior.

The coordinates over the specific CRS are stored internally as a plain `NTuple{N, T}` (where `T <: AbstractFloat` is currently enforced during construction) which holds the raw coordinates (i.e. without unit and transformed to the preferred, usually SI, unit. This means that for example if a specific CRS has the unit of `u"km"`, the raw values stored internally are the numerical value in meters)

"""
struct Coordinate{CRS <: AbstractCRS, T, N} <: AbstractSatcomCoordinate{CRS, T, N}
    crs::CRS
    tuplecoords::NTuple{N, T}

    BasicTypes.constructor_without_checks(::Type{Coordinate}, crs::CRS, tuplecoords::NTuple{N, T}) where {CRS <: AbstractCRS, T, N} = new{CRS, T, N}(crs, tuplecoords)
end

(C::Type{<:AbstractSatcomCoordinate})(args::Vararg{Any, N}) where {N} = create_coordinate(C, args...)

const Pointing{CRS <: AbstractPointingCRS, T, N} = Coordinate{CRS, T, N}

create_coordinate(C::Type{<:AbstractSatcomCoordinate}, args::Point{M, Number}) where {M} = create_coordinate(C, args...)
create_coordinate(C::Type{<:AbstractSatcomCoordinate}, crs::AbstractCRS, args::Point{M, Number}) where {M} = create_coordinate(C, crs, args...)
function create_coordinate(C::Type{<:AbstractSatcomCoordinate}, coords::Vararg{Number, M}) where {M}
    return create_coordinate(C, defaultcrs(C), coords...)
end
function create_coordinate(C::Type{<:AbstractSatcomCoordinate}, crs::AbstractCRS, coords::Vararg{Number, M}) where {M}
    N = ncoords(crs)
    N == M || throw(DimensionMismatch("The number of coordinates provided ($(M)) does not match the number of coordinates expected by the provided CRS ($(N))"))
    # We check that if a crs was provided in the coordinate type signature, that it matches the provided crs instance
    CRS = typeof(crs)
    if crstype(C) !== Union{}
        crstype(C) == CRS || throw(ArgumentError("The provided crs does not match the crs type signature of the coordinate type $C"))
    end
    CT = valuetype(C)
    T = bypass_bottom(CT, common_valuetype(AbstractFloat, Float64, coords...))
    tup = preprocess_input_coords(CRS, T, coords)
    raw = process_unitless_coords(C, crs, tup)
    return constructor_without_checks(basetype(C), crs, raw)
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

for T in (Vararg{Number}, Point{N, Number} where N)
    @eval function (CRS::Type{<:AbstractCRS})(coords::$T{N}) where {N}
        N == ncoords(CRS) || throw(DimensionMismatch("The number of coordinates provided ($(N)) does not match the number of coordinates expected by CRS of type $CRS ($(ncoords(CRS)))"))
        if isderivedcrs(CRS)
            # This simply calls the next method below, which takes both the wrapped CRS and the coords as input
            return basetype(CRS)(default_wrappedcrs(CRS), coords)
        else
            return Coordinate(CRS(), coords)
        end
    end

    @eval function (CRS::Type{<:AbstractCRS})(wrapped_crs::AbstractCRS, coords::$T{N}) where {N}
        N == ncoords(CRS) || throw(DimensionMismatch("The number of coordinates provided ($(N)) does not match the number of coordinates expected by CRS of type $CRS ($(ncoords(CRS)))"))
        isderivedcrs(CRS) || throw(ArgumentError("The provided CRS is not derived from another CRS, so it cannot be instantiated with another CRS as first argument"))
        crs = basetype(CRS)(wrapped_crs)
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
    if isderivedcrs(c)
        return PlutoShowHelpers.shortname(c) * "{" * PlutoShowHelpers.shortname(linkedcrs(c)) * "}"
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