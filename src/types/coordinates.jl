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
    raw = process_unitless_coords(C, crs, tup)
    return constructor_without_checks(basetype(C){CRS, T}, crs, raw)
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

default_wrappedcrs(::Type{<:AbstractCRS}) = Cartesian()

@inline Base.propertynames(coord::AbstractSatcomCoordinate) = propertynames(units(crs(coord)))


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
    tup = transform_tuplecoords(crsₒ, crs(coord), tuplecoords(coord))
    return constructor_without_checks(basetype(typeof(coord)){typeof(crsₒ), valuetype(typeof(coord))}, crsₒ, tup)
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