# Helper function to find how many fields which subtype AbstractCRS a specific CRS type has
nlinked_crs(C::Type{<:AbstractCRS}) = count(T -> T <: AbstractCRS, fieldtypes(C))


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
hascrstrait(traitfunc, CRS::Type{<:AbstractCRS}) = return traitfunc(traitcrs(CRS, traitfunc))
hascrstrait(traitfunc, crs::AbstractCRS) = return hascrstrait(traitfunc, typeof(crs))

# This simply unwraps the CRS that must be used to check for the trait from the input CRS. It is only relevant for complex CRSs that need to forward the trait check to another CRS within their type. The first signature with both CRS and function is what is called by the default method of hascrstrait, and can be used to further customize the CRS to check the trait on depending on the specific trait function.
traitcrs(CRS::Type{<:AbstractCRS}, ::Function) = return traitcrs(CRS)
traitcrs(CRS::Type{<:AbstractCRS}) = CRS

"""
    isrootcrs(C::Type{<:AbstractCRS})
    isrootcrs(crs::AbstractCRS)

Return `true` if the CRS `C` is a root CRS, `false` otherwise.

A root CRS is a CRS which is not derived or linked to any other CRS.

All root CRSs should also be cartesian CRSs

See also: [`rootcrs`](@ref), [`iscartesiancrs`](@ref)
"""
function isrootcrs(::Type{C}) where {C<:AbstractCRS}
    return nlinked_crs(C) == 0
end
isrootcrs(crs::AbstractCRS) = isrootcrs(typeof(crs))

"""
    islinkedcrs(C::Type{<:AbstractCRS})
    islinkedcrs(crs::AbstractCRS)

Return `true` if the CRS `C` is linked to any other CRS, `false` otherwise.

The difference between a **linked CRS** and a **derived CRS** is that the latter can only be defined on top of its linked CRS, the second is instead encompassing all CRSs which are linked to (at least) one other CRS.

An example of a **derived CRS** is the `LLA` CRS which is only defined on top of an `ECEF` CRS.

An example of a **linked CRS** which is not also a **derived CRS** is a Cartesian CRS which is referenced to another Cartesian CRS via a user-defined affine transformation.

By default, this function returns `true` if the CRS has at least one field which is a subtype of `AbstractCRS`, `false` otherwise.

See also: [`linkedcrs`](@ref), [`isrootcrs`](@ref)
"""
islinkedcrs(::Type{C}) where {C<:AbstractCRS} = nlinked_crs(C) > 0
islinkedcrs(crs::AbstractCRS) = islinkedcrs(typeof(crs))



"""
    iscartesiancrs(C::Type{<:AbstractCRS})
    iscartesiancrs(crs::AbstractCRS)

Return `true` if the CRS `C` is a Cartesian CRS, `false` otherwise.

The default implementation assumes a CRS is cartesian if it has 3 dimensions and all of them have units of length.

See also: [`cartesiancrs`](@ref), [`isrootcrs`](@ref), [`islinkedcrs`](@ref)
"""
iscartesiancrs(C::Type{<:AbstractCRS}) = ncoords(C) == 3 && all(u -> u isa Unitful.LengthUnits, units(C))
iscartesiancrs(crs::AbstractCRS) = iscartesiancrs(typeof(crs))
