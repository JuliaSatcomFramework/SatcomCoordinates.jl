# Helper function to find how many fields which subtype AbstractCRS a specific CRS type has
nlinked_crs(C::Type{<:AbstractCRS}) = count(T -> T <: AbstractCRS, fieldtypes(C))

struct NoCRSFallback <: AbstractCRS end

"""
    hascrstrait(traitfunc::Function, crs::AbstractCRS)

This is an helper function which should be used in the definition of the default method for a trait function.
For example, the `istopocentriccrs` trait function's default method is actually defined as follows:
```julia
istopocentriccrs(obj) = hascrstrait(istopocentriccrs, obj)
hascrstrait(::typeof(istopocentriccrs), ::Type{<:AbstractCRS}) = false
```

This is mainly done to simplify the handling of complex linked CRSs (like AffineCartesian) which should actually forward all the trait functions to their base CRS.

Custom CRSs that simply need to add a method to an existing CRS trait function do not need to use this function, and this is only needed to be extended by a downstream user/developer when defining completely new CRS traits.

The three basic CRS traits below are not defined using this function as they rely on core properties of all CRSs for their default implementation:
- [`iscartesiancrs`](@ref)
- [`isrootcrs`](@ref)
- [`islinkedcrs`](@ref)
"""
function hascrstrait(traitfunc, ::Type{CRS}) where {CRS<:AbstractCRS}
    traitfunc === linkedcrs && return nlinked_crs(CRS) > 0 # We have a special case for the linkedcrs trait as can't check if the CRS type is the same as the input for linkedcrs
    if applicable(traitfunc, CRS)
        # We have an explicit method taking the CRS type as input, so we just check that it returns CRS itself
        return traitfunc(CRS) === CRS
    else
        # We first try to see if the traitcrs returns 
        TRAIT_CRS = traitcrs(CRS)
        if TRAIT_CRS === CRS
            return false # We don't have to check trait on another CRS and there is not method explicitly added to specify that `traitfunc` is true for this CRS
        else
            # We forward the check on the trait crs
            return hascrstrait(traitfunc, TRAIT_CRS)
        end
    end
end
hascrstrait(traitfunc, crs::AbstractCRS) = return hascrstrait(traitfunc, typeof(crs))
hascrstrait(traitfunc::Function) = Base.Fix1(hascrstrait, traitfunc)
hascrstrait(traitfunc::Function, obj::FieldOrCoordinate) = return hascrstrait(traitfunc, getcrs(obj))

function traitcrs(obj::Union{AbstractCRS, Type{<:AbstractCRS}})
    CRS = getcrstype(obj)
    if applicable(crsfield, traitcrs, CRS)
        # We have to forward the trait to a custom field
        fname = crsfield(traitcrs, CRS)::Symbol
        return _extract_crsfield(obj, fname)
    else
        return obj
    end
end

# Every trait function should return the first CRS in the nested hieararch that satisfies the trait or in case none do, return `Union{}`

"""
    rootcrs(C::Type{<:AbstractCRS})

Returns the **Root CRS** type associated to the provided _CRS_ type `C`

A root CRS is a CRS which is not derived or linked to any other CRS.

All root CRSs should also be cartesian CRSs

See also: [`rootcrs`](@ref), [`cartesiancrs`](@ref)
"""
function rootcrs(::Type{CRS}) where {CRS<:AbstractCRS}
    return nlinked_crs(CRS) == 0 ? CRS : NoCRSFallback
end

"""
    cartesiancrs(C::Type{<:AbstractCRS})

Returns the first **Cartesian CRS** type associated to the provided _CRS_ type `C`.

A Cartesian CRS is a CRS which is defined in a 3D cartesian space.

Any new custom Cartesian CRS type should define a method for this function that returns the Cartesian CRS type when given the custom CRS type as input.

See also: [`cartesiancrs`](@ref), [`rootcrs`](@ref), [`linkedcrs`](@ref)
"""
function cartesiancrs(::Type{C}) where {C<:AbstractCRS}
    if ncoords(C) == 3 && all(u -> u isa Unitful.LengthUnits, units(C)) 
        return C 
    else
        return NoCRSFallback
    end
end

"""
    linkedcrs

CRS Trait function identifying that a CRS is linked to another CRS.

For this specific trait, the `getcrs` and `getcrstype` functions will return the instance or type of the linked CRS.
"""
function linkedcrs end