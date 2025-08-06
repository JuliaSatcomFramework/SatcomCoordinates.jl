"""
    upreferred(CRS::Type, unit::Unitful.Units)
    
Allow to customize the preferred unit on different types of CRSs. Defaults to `Unitful.upreferred(unit)`.

!!! note
    This is not the same function as `Unitful.upreferred` but just shares the same name as they basically have the same end goal. It is nonetheless redefined internally to `SatComCoordinates` to avoid polluting the methods of `Unitful.upreferred`.
"""
upreferred(unit::Unitful.Units) = Unitful.upreferred(unit)
upreferred(::Union{typeof(u"°"), typeof(u"rad")}) = return u"rad"

"""
    add_unit(userunit::Unitful.Units, refunit::Unitful.Units, val::Real)

Take a real value, add the `refunit` to it and then convert it to `userunit` using `Unitful.uconvert`.

This is used internally in the `coords` function to transform the raw coordinates stored in a `Coordinate` type into unitful values according to the units of the specific CRS.
"""
add_unit(userunit::Unitful.Units, refunit::Unitful.Units, val::Real) = enforce_unit(refunit, val) |> userunit

"""
    remove_unit(userunit::Unitful.Units, refunit::Unitful.Units, val::Number)

Take a number (with or without unit), convert or interpret it (depending on whether it has or not a unit) to the `userunit`, convert again to `refunit` and then strip the unit.

This is used internally in the constructor of `Coordinate`s to convert user inputs into the raw coordinate for the specific CRS.
"""
remove_unit(userunit::Unitful.Units, refunit::Unitful.Units, val::Number) = enforce_unit(userunit, val) |> refunit |> ustrip


@inline ncoords(::Type{<:AbstractSatcomCoordinate{<:Any, <:Any, N}}) where N = return N
@inline ncoords(::Type{CRS}) where CRS <: AbstractCRS = return length(units(CRS))
@inline ncoords(obj::Union{AbstractCRS, FieldOrCoordinate, Transform, Point}) = return ncoords(typeof(obj))
# NCoords for the transformations, which have an input and output dimension
for f in (:ncoords_out, :ncoords_in)
    @eval $f(T::Type{<:Transform}) = return ncoords(T)
    @eval $f(t::Transform) = return $f(typeof(t))
end
ncoords_out(::Type{<:AbstractCRSTransform{CRSₒ}}) where CRSₒ = return ncoords(CRSₒ)
ncoords_in(::Type{<:AbstractCRSTransform{<:Any, CRSᵢ}}) where CRSᵢ = return ncoords(CRSᵢ)

"""
    struct AnyN end

Singletone structure just used to match any integer number
"""
struct AnyN end
Base.:(==)(::AnyN, ::Integer) = return true
Base.:(==)(::Integer, ::AnyN) = return true
ncoords(::Type{Identity}) = return AnyN()

# Inner ncoords helpers
ncoords(::Type{<:Rotation{N}}) where {N} = N
ncoords(::Type{<:Point{N}}) where {N} = return N


units(::CRS) where CRS <: AbstractCRS = units(CRS)
referenceunits(CRS::Type{<:AbstractCRS}) = map(upreferred, units(CRS))

tuplecoords(coord::AbstractSatcomCoordinate) = getfield(coord, :tuplecoords)

function rawcoords(coord::AbstractSatcomCoordinate)
    CRS = getcrstype(coord)
    userunits = units(CRS)
    coords = tuplecoords(coord)
    return NamedTuple{keys(userunits)}(coords)
end

function coords(coord::AbstractSatcomCoordinate)
    CRS = getcrstype(coord)
    userunits = units(CRS)
    refunits = referenceunits(CRS)
    c = tuplecoords(coord)
    vals = ntuple(ncoords(CRS)) do i
        add_unit(userunits[i], refunits[i], c[i])
    end
    return NamedTuple{keys(userunits)}(vals)
end



function check_cartesian_wrapped(CRS::Type{<:AbstractCRS}, wrapped::AbstractCRS) 
    hascrstrait(cartesiancrs, wrapped) || throw(ArgumentError("CRSs of type $(basetype(CRS)) must be defined over a Cartesian CRS, while the provided CRS ($(typeof(wrapped))) is not a Cartesian one."))
end

function change_crs(crsₒ::AbstractCRS, coord::AbstractSatcomCoordinate; kwargs...)
    tup = transform_tuplecoords(crsₒ, crs(coord), tuplecoords(coord); kwargs...)
    return constructor_without_checks(basetype(typeof(coord)), crsₒ, tup)
end
function change_crs(traitfunc::Function, coord::AbstractSatcomCoordinate; kwargs...)
    raw, crsₒ, crsᵢ = _getcrstransform_raw_bothcrs(traitfunc, coord)
    tup = raw(tuplecoords(coord))
    return constructor_without_checks(basetype(typeof(coord)), crsₒ, tup)
end
change_crs(obj) = Base.Fix1(change_crs, obj)

_missing_conversion_method(crsₒ, crsᵢ) = throw(ArgumentError("No conversion is defined to go from an input CRS of type `$(typeof(crsᵢ))` to an output CRS of type `$(typeof(crsₒ))`.\nConsider adding a specific method to `SatcomCoordinates.transform_tuplecoords` to support this conversion if necessary."))

"""
    transform_tuplecoords(crsₒ::AbstractCRS, crsᵢ::AbstractCRS, tup::NTuple{N, <:AbstractFloat}; kwargs...)

Low-level function that is used to convert to an output CRS (`CRSₒ`) the raw coordinates `tup` (coming as output of `tuplecords`) of a coordinate in an input CRS (`CRSᵢ`).

This function must return a ntuple with `M` coordinates (where `M == ncoords(CRSₒ)`).

Custom CRSs should implement a specific method of this function to enable conversion with other CRSs via the `change_crs` user facing function.
"""
function transform_tuplecoords(crsₒ::AbstractCRS, crsᵢ::AbstractCRS, tup::Any; kwargs...)
    if is_same_crs(crsₒ, crsᵢ)
        return tup
    elseif is_same_crs(crsₒ, _extract_crs(linkedcrs, crsᵢ))
        return raw_linkedcrs_transform(crsᵢ)(tup)
    elseif is_same_crs(_extract_crs(linkedcrs, crsₒ), crsᵢ)
        t = TransformsBase.inverse(raw_linkedcrs_transform(crsₒ))
        return t(tup)
    elseif is_same_crs(getcrs(rootcrs, crsₒ), getcrs(rootcrs, crsᵢ))
        t1 = getcrstransform_raw(rootcrs, crsᵢ) # This goes from input to root
        t2 = getcrstransform_raw(rootcrs, crsₒ) |> inverse # This goes from root to output
        return t2(t1(tup))
    else
        _missing_conversion_method(crsₒ, crsᵢ)
    end
end
function transform_tuplecoords(crsₒ::AbstractLinkedCRS{CRS}, crsᵢ::AbstractLinkedCRS{CRS}, tup::Any; kwargs...) where CRS <: AbstractCRS
    if is_same_crs(crsₒ, crsᵢ)
        return tup
    elseif is_same_crs(getcrs(linkedcrs, crsₒ), getcrs(linkedcrs, crsᵢ))
        # We pass through the common linked crs
        intermediate = raw_linkedcrs_transform(crsᵢ)(tup)
        rt = TransformsBase.inverse(raw_linkedcrs_transform(crsₒ))
        return rt(intermediate)
    else
        _missing_conversion_method(crsₒ, crsᵢ)
    end
end

"""
    rand_tuplecoords(rng::AbstractRNG, crs::AbstractCRS, T::Type{<:AbstractFloat})

This is the internal function that new custom CRSs should implement to support random generation of Coordinates in the CRS

New methods for this should generate a tuple of valid coordinates for the provided `crs` and use the provided `T` as machine precision.

It is called automatically when doing `rand(crs)` where `crs` is an instance of `AbstractCRS`.

!!! note "Default implementation"
    All Cartesian CRSs have a default implementation (if not overridden) that simply generates a tuple of 3 random values via `rand(rng, T)`.
"""

function rand_tuplecoords(rng::AbstractRNG, crs::AbstractCRS, T::Type{<:AbstractFloat})
    hascrstrait(cartesiancrs, crs) || throw(ArgumentError("The default method for generating random coordinates works only for Cartesian CRSs.\nAdd a custom method to `SatcomCoordinates.rand_tuplecoords` to support random generation of coordinates in the CRS $(basetype(crs))."))
    return ntuple(i -> rand(rng, T), ncoords(crs))
end

"""
    raw_linkedcrs_transform(crs::AbstractCRS)

Returns the raw transform that goes from the provided `crs` to its linked one.

This function should return a **raw** transformation (i.e. a transformation operating directly the output of `tuplecoords(coordinate)` rather than on the coordinate itself).

A **raw** transformation shall expects a NTuple{N, <:AbstractFloat} as input (where `N` is the number of dimensions of the CRS) and return a NTuple{N, <:AbstractFloat} as output.
"""
function raw_linkedcrs_transform end

"""
    is_same_crs(crs1::AbstractCRS, crs2::AbstractCRS)

Returns `true` or `false` to indicate whether the two provided CRSs are the same.

Defaults to true for CRSs of the same type and false otherwise.

This is done in place of simply doing `crs1 == crs2` because it's slightly faster when the check can be done at compile time (on the types only).

Custom CRSs which may be different despite having the same type (e.g. the Topocentric CRSs) should override this function accordingly.
"""
is_same_crs(crs1::AbstractCRS, crs2::AbstractCRS) = return false
is_same_crs(crs1::CRS, crs2::CRS) where CRS <: AbstractCRS = return true
is_same_crs(crs1::CRS, crs2::CRS) where{DCRS <: AbstractCRS, CRS <: AbstractLinkedCRS{DCRS}} = is_same_crs(getcrs(linkedcrs, crs1), getcrs(linkedcrs, crs2))

# This is to simplify normalizing a tuple
_normalize(tup::NTuple) = Tuple(normalize(SVector(tup)))