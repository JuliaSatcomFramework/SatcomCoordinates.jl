function crsfield(::typeof(linkedcrs), CRS::Type{<:AbstractCRS})
    return fieldname_oftype(CRS, <:, AbstractCRS)
end
_validfieldname(s::Symbol) = s !== FIELDNAME_NOT_FOUND_SYMBOL

isvalidcrs(::Union{AbstractCRS, Type{<:AbstractCRS}}) = true
isvalidcrs(::Union{NoCRSFallback, Type{<:NoCRSFallback}}) = false

Base.@constprop :aggressive _extract_crsfield(::Type{CRS}, fname::Symbol) where {CRS <: AbstractCRS} = return fieldtype(CRS, fname)
Base.@constprop :aggressive _extract_crsfield(crs::CRS, fname::Symbol) where {CRS <: AbstractCRS} = return getfield(crs, fname)

# This function extract the instance or Type of the nested CRS satisfying the trait without recursion. It simply returns the NoCRSFallback if either 
function _extract_crs(traitfunc::Function, obj::Union{AbstractCRS, Type{<:AbstractCRS}})
    typeinp = obj isa Type
    default = typeinp ? NoCRSFallback : NoCRSFallback()
    applicable(traitfunc, obj) && return traitfunc(obj)
    CRS = typeinp ? obj : typeof(obj)
    applicable(crsfield, traitfunc, CRS) || return default
    fname = crsfield(traitfunc, CRS)
    _validfieldname(fname) || return default
    return typeinp ? fieldtype(obj, fname) : getfield(obj, fname)
end

# This function try to recurse the provided crs (Type or instance) to find the first nested CRS (type or instance) for which the traitfunc is applicable. If no such CRS is found, it returns the NoCRSFallback (either the type or the instance, depending on whether the input object was a CRS Type or instance).
function _recurse_crs(traitfunc::F, obj::O) where {F <: Function, O <: Union{AbstractCRS, Type{<:AbstractCRS}}}
    out = _extract_crs(traitfunc, obj)
    isvalidcrs(out) && return out
    hascrstrait(traitfunc, obj) && return obj
    linked = _extract_crs(linkedcrs, obj)
    isvalidcrs(linked) || return linked
    return _recurse_crs(traitfunc, linked)
end

_crsfallback_exception(traitfunc, CRS::Type{<:AbstractCRS}) = ArgumentError("Could not find a crs satisfying the `$traitfunc` trait while traversing the nested CRSs within the provided CRS (of type `$CRS`)")

getcrs(traitfunc::Function) = Base.Fix1(getcrs, traitfunc)
@inline getcrs(obj::O) where {O} = return getcrs(crs, obj)
function getcrs(traitfunc::Function, crs::AbstractCRS)
    outcrs = _recurse_crs(traitfunc, crs)
    isvalidcrs(outcrs) || throw(_crsfallback_exception(traitfunc, typeof(crs)))
    return outcrs
end
getcrs(traitfunc::F, obj::FieldOrCoordinate) where {F <: Function} = return getcrs(traitfunc, crs(obj))

getcrstype(traitfunc::Function) = Base.Fix1(getcrstype, traitfunc)
@inline getcrstype(obj::O) where {O} = return getcrstype(crs, obj)
getcrstype(::Function, T::Type) = throw(ArgumentError("The provided type $T is not (or does not store) a valid CRS type."))
function getcrstype(traitfunc::Function, ::Type{CRS}) where {CRS<:AbstractCRS}
    OUT = _recurse_crs(traitfunc, CRS)
    isvalidcrs(OUT) || throw(_crsfallback_exception(traitfunc, CRS))
    return OUT
end
getcrstype(getterfunc::F, obj) where {F <: Function} = return getcrstype(getterfunc, typeof(obj))
getcrstype(getterfunc::F, ::Type{<:FieldOrCoordinate{CRS}}) where {F <: Function, CRS <: AbstractCRS} = return getcrstype(getterfunc, CRS)

# This is the basic internal function, which returns the 
crs(coord::AbstractSatcomCoordinate) = return getfield(coord, :crs)
crs(c::AbstractCRS) = return c
# Version for types
crs(CRS::Type{<:AbstractCRS}) = return CRS

# This function traverses the tree to get the raw crs transform

function _getcrstransform_raw(traitfunc::Function, crs::AbstractCRS)
    hascrstrait(linkedcrs, crs) || return Identity() # If this is false, we are at the root
    traitfunc !== linkedcrs && hascrstrait(traitfunc, crs) && return Identity() # The provided CRS is already satisfying the trait so we just return identity
    raw = raw_linkedcrs_transform(crs)
    traitfunc === linkedcrs && return raw
    linked = getcrs(linkedcrs, crs)
    return _compose(raw, _getcrstransform_raw(traitfunc, linked))
end

"""
    getcrstransform_raw(traitfunc::Function, crsᵢ::AbstractCRS)
    getcrstransform_raw(traitfunc::Function, coord::FieldOrCoordinate)

Return the raw transformation that translates raw coordinates (i.e. tuples of numbers) from the input crs `crsᵢ` (eventually extracted from the coordinate `coord`) to the first CRS within the nested CRS tree of `crsᵢ` which satisfies the provided trait `traitfunc`.

If the CRS `crsᵢ` is already satisfying the trait `traitfunc`, this function returns the identity transformation.

If a CRS satisfying `traitfunc` can not be found within the CRS tree of `crsᵢ`, an error is thrown.

See also: [`getcrstransform`](@ref)
"""
function getcrstransform_raw(traitfunc::Function, crsᵢ::AbstractCRS)
    found_crs = _recurse_crs(traitfunc, crsᵢ) # This we use to check at compile time whether there is a nested CRS satisfying the trait
    isvalidcrs(found_crs) || throw(_crsfallback_exception(traitfunc, typeof(crsᵢ)))
    return _getcrstransform_raw(traitfunc, crsᵢ)
end
getcrstransform_raw(traitfunc::F, obj::FieldOrCoordinate) where {F <: Function} = return getcrstransform_raw(traitfunc, getcrs(obj))

"""
    getcrstransform(traitfunc::Function, crsᵢ::AbstractCRS)
    getcrstransform(traitfunc::Function, coord::FieldOrCoordinate)

Return the transformation taking as input a Coordinate in the input crs `crsᵢ` (eventually extracted from the coordinate `coord`) and returning as output a Coordinate in the output CRS identified as the first CRS within the nested CRS tree of `crsᵢ` which satisfies the provided CRS trait `traitfunc`.

If a CRS satisfying `traitfunc` can not be found within the CRS tree of `crsᵢ`, an error is thrown.

The returned transformation is an instance of `CRSTransform`.

!!! note 
    This function simply calls `getcrstransform_raw` and wraps the result in a `CRSTransform` object.

# Example
```julia
using SatcomCoordinates

# We first create a NED CRS at a specific location above Earth
enu_crs = ENU(LLA(0,0,1200km))

# We then create a Spherical CRS (AzEl) that is linked to the ENU CRS. This is a double nested CRS as it's itself based on a ENU which is based on an ECEF CRS.
aer_crs = SphericalCRS(AzEl(enu_crs))

getcrs(linkedcrs, aer_crs) == enu_crs # The linked CRS is the one immediately below the provided CRS, which is the ENU CRS

getcrs(rootcrs, aer_crs) == ECEF() # The root CRS is the one at the bottom of the nested CRS, which is the ECEF CRS

# Extract the transformation towards the linked CRS (NED)
tlinked = getcrstransform(linkedcrs, aer_crs)

# 90° el, 10m distance is (0,0,10) in ENU
tlinked(aer_crs(0,90,10)) ≈ enu_crs(0,0,10) # The transformation is applied to the coordinate

# We now extract the transformation towards the root CRS (ECEF)
troot = getcrstransform(rootcrs, aer_crs)

# Check that the origin is correctly transformed
troot(aer_crs(0,90,0)) ≈ ecef_origin(aer_crs)
```

See also: [`CRSTransform`](@ref), [`getcrstransform_raw`](@ref)
"""
function getcrstransform(traitfunc::Function, crsᵢ::AbstractCRS)
    crsₒ = _recurse_crs(traitfunc, crsᵢ)
    isvalidcrs(crsₒ) || throw(_crsfallback_exception(traitfunc, typeof(crsᵢ)))
    raw = _getcrstransform_raw(traitfunc, crsᵢ)
    return CRSTransform(crsₒ, crsᵢ, raw)
end
getcrstransform(traitfunc::F, obj::FieldOrCoordinate) where {F <: Function} = return getcrstransform(traitfunc, getcrs(obj))