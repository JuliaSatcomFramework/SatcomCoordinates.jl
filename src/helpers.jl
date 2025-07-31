"""
    upreferred(CRS::Type, unit::Unitful.Units)
    
Allow to customize the preferred unit on different types of CRSs. Defaults to `Unitful.upreferred(unit)`.

!!! note
    This is not the same function as `Unitful.upreferred` but just shares the same name as they basically have the same end goal. It is nonetheless redefined internally to `SatComCoordinates` to avoid polluting the methods of `Unitful.upreferred`.
"""
upreferred(unit::Unitful.Units) = Unitful.upreferred(unit)
upreferred(::Union{typeof(u"°"), typeof(u"rad")}) = u"rad"

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


@inline ncoords(::Type{<:AbstractSatcomCoordinate{<:Any, <:Any, N}}) where N = N
@inline ncoords(::Type{CRS}) where CRS <: AbstractCRS = length(units(CRS))
@inline ncoords(obj::Union{AbstractCRS, FieldOrCoordinate, Transform}) = ncoords(typeof(obj))
# NCoords for the transformations, which have an input and output dimension
for f in (:ncoords_out, :ncoords_in)
    @eval $f(T::Type{<:Transform}) = ncoords(T)
    @eval $f(t::Transform) = $f(typeof(t))
end
ncoords_out(::Type{<:AbstractCRSTransform{CRSₒ}}) where CRSₒ = ncoords(CRSₒ)
ncoords_in(::Type{<:AbstractCRSTransform{<:Any, CRSᵢ}}) where CRSᵢ = ncoords(CRSᵢ)

"""
    struct AnyN end

Singletone structure just used to match any integer number
"""
struct AnyN end
Base.:(==)(::AnyN, ::Integer) = true
Base.:(==)(::Integer, ::AnyN) = true
ncoords(::Type{Identity}) = AnyN()

# Inner ncoords helpers
ncoords(::Type{<:Rotation{N}}) where {N} = N
ncoords(::Type{<:SVector{N}}) where {N} = N
ncoords(v::Union{SVector, NTuple}) = length(v)

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



function check_cartesian_wrapped(CRS::Type{<:AbstractCRS}, wrapped::AbstractCRS) 
    iscartesiancrs(basecrs(wrapped)) || throw(ArgumentError("CRSs of type $(basetype(CRS)) must be defined over a Cartesian CRS, while the provided CRS ($(typeof(wrapped))) is not a Cartesian one."))
end

defaultcrs(::Type{<:AbstractSatcomCoordinate{CRS}}) where CRS <: AbstractCRS = CRS()
defaultcrs(::Type{<:AbstractSatcomCoordinate{<:Any}}) = Cartesian()
defaultcrs(::Type{Pointing}) = ThetaPhi()

default_wrappedcrs(::Type{<:AbstractCRS}) = Cartesian()


function change_crs(crsₒ::AbstractCRS, coord::AbstractSatcomCoordinate; kwargs...)
    tup = transform_tuplecoords(crsₒ, crs(coord), tuplecoords(coord); kwargs...)
    return constructor_without_checks(basetype(typeof(coord)), crsₒ, tup)
end
function change_crs(crsₒ::CRS, coord::AbstractSatcomCoordinate{CRS}; kwargs...) where CRS <: AbstractCRS
    crsᵢ = crs(coord)
    if is_same_crs(crsₒ, crsᵢ)
        # We have to do this check as we may have two different instances of the same CRS
        return coord 
    else
        tup = transform_tuplecoords(crsₒ, crsᵢ, tuplecoords(coord); kwargs...)
        return constructor_without_checks(basetype(typeof(coord)), crsₒ, tup)
    end
end

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
    elseif is_same_crs(crsₒ, linkedcrs(crsᵢ))
        return raw_linkedcrs_transform(crsᵢ)(tup)
    elseif is_same_crs(linkedcrs(crsₒ), crsᵢ)
        t = TransformsBase.inverse(raw_linkedcrs_transform(crsₒ))
        return t(tup)
    elseif is_same_crs(rootcrs(crsₒ), rootcrs(crsᵢ))
        t1 = raw_rootcrs_transform(crsᵢ) # This goes from input to root
        t2 = raw_rootcrs_transform(crsₒ) |> inverse # This goes from root to output
        return t2(t1(tup))
    else
        _missing_conversion_method(crsₒ, crsᵢ)
    end
end
function transform_tuplecoords(crsₒ::AbstractLinkedCRS{CRS}, crsᵢ::AbstractLinkedCRS{CRS}, tup::Any; kwargs...) where CRS <: AbstractCRS
    if is_same_crs(linkedcrs(crsₒ), linkedcrs(crsᵢ))
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
rand_tuplecoords(crs::AbstractCRS, T::Type{<:AbstractFloat} = Float64) = rand_tuplecoords(Random.default_rng(), crs, T)

function rand_tuplecoords(rng::AbstractRNG, crs::AbstractCRS, T::Type{<:AbstractFloat})
    iscartesiancrs(basecrs(crs)) || throw(ArgumentError("The default method for generating random coordinates works only for Cartesian CRSs.\nAdd a custom method to `SatcomCoordinates.rand_tuplecoords` to support random generation of coordinates in the CRS $(basetype(crs))."))
    return ntuple(i -> rand(rng, T), ncoords(crs))
end

"""
    linkedcrs_transform(crs::AbstractCRS)

Returns the CRSTransform that goes from the provided `crs` to its linked one (It simply returns the Identity transform in case the linked CRS is the same as the provided one).

As an example, for a `LLA` CRS, the output of `linkedcrs_transform` should be a `CRSTransform` that accepts a `LLA` coordinate and returns an `ECEF` coordinate as output (in the ECEF CRS linked to the provided LLA CRS).

This function relies internally on the `raw_linkedcrs_transform` function to return the raw transform. And custom CRSs shall add a method to [`raw_linkedcrs_transform`](@ref) directly.
"""
function linkedcrs_transform(crs::AbstractCRS)
    linked = linkedcrs(crs)
    if linked === crs
        return Identity()
    else
        raw = raw_linkedcrs_transform(crs)
        return CRSTransform(linked, crs, raw)
    end
end

"""
    raw_linkedcrs_transform(crs::AbstractCRS)

Returns the raw transform that goes from the provided `crs` to its linked one.

This function should return a **raw** transformation (i.e. a transformation operating directly the output of `tuplecoords(coordinate)` rather than on the coordinate itself).

A **raw** transformation shall expects a NTuple{N, <:AbstractFloat} as input (where `N` is the number of dimensions of the CRS) and return a NTuple{N, <:AbstractFloat} as output.
"""
function raw_linkedcrs_transform(crs::AbstractCRS)
    linked = linkedcrs(crs)
    if is_same_crs(crs, linked)
        return Identity()
    else
        throw(ArgumentError("The provided CRS has a linked CRS but does not seem to implement an appropriate method for `SatcomCoordinates.raw_linkedcrs_transform`, which is a required method for all custom CRSs."))
    end
end

function raw_rootcrs_transform(crs::AbstractCRS)
    isrootcrs(crs) && return Identity()
    linked = linkedcrs(crs)
    raw = raw_linkedcrs_transform(crs)
    return _compose(raw, raw_rootcrs_transform(linked))
end

"""
    is_same_crs(crs1::AbstractCRS, crs2::AbstractCRS)

Returns `true` or `false` to indicate whether the two provided CRSs are the same.

Defaults to true for CRSs of the same type and false otherwise.

This is done in place of simply doing `crs1 == crs2` because it's slightly faster when the check can be done at compile time (on the types only).

Custom CRSs which may be different despite having the same type (e.g. the Topocentric CRSs) should override this function accordingly.
"""
is_same_crs(crs1::AbstractCRS, crs2::AbstractCRS) = false
is_same_crs(crs1::CRS, crs2::CRS) where CRS <: AbstractCRS = true
is_same_crs(crs1::CRS, crs2::CRS) where{DCRS <: AbstractCRS, CRS <: AbstractLinkedCRS{DCRS}} = is_same_crs(linkedcrs(crs1), linkedcrs(crs2))