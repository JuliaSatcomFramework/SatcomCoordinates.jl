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

crs(coord::AbstractSatcomCoordinate) = return getfield(coord, :crs)
crs(c::AbstractCRS) = return c
# Version for types
crs(CRS::Type{<:AbstractCRS}) = return CRS