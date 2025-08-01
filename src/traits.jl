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
hascrstrait(traitfunc, obj::FieldOrCoordinate) = return hascrstrait(traitfunc, crs(obj))

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
    rootcrs(crs::AbstractCRS)

Return the root CRS of the provided CRS `crs`. This basically traverses recursively all the CRSs `crs` is derived from until it finds the root one.

See also: [`isrootcrs`](@ref), [`linkedcrs`](@ref)
"""
function rootcrs(crs::AbstractCRS)
    isrootcrs(crs) && return crs
    linked = linkedcrs(crs)
    return rootcrs(linked)
end
rootcrs(coord::FieldOrCoordinate) = rootcrs(crs(coord))

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
    linkedcrs(crs::AbstractCRS)

Return the CRS instance that is **linked** to the provided `crs` if it exists, otherwise return the `crs` itself.

By default, this function returns the first field within the provided `crs` which is a subtype of `AbstractCRS`.
"""
function linkedcrs(crs::AbstractCRS)
    if islinkedcrs(crs)
        return getproperty_oftype(crs, AbstractCRS)
    else
        return crs
    end
end
linkedcrs(coord::FieldOrCoordinate) = linkedcrs(crs(coord))

"""
    iscartesiancrs(C::Type{<:AbstractCRS})
    iscartesiancrs(crs::AbstractCRS)

Return `true` if the CRS `C` is a Cartesian CRS, `false` otherwise.

The default implementation assumes a CRS is cartesian if it has 3 dimensions and all of them have units of length.

See also: [`cartesiancrs`](@ref), [`isrootcrs`](@ref), [`islinkedcrs`](@ref)
"""
iscartesiancrs(C::Type{<:AbstractCRS}) = ncoords(C) == 3 && all(u -> u isa Unitful.LengthUnits, units(C))
iscartesiancrs(crs::AbstractCRS) = iscartesiancrs(typeof(crs))

"""
    cartesiancrs(crs::AbstractCRS)

Recursively traverse the CRSs wrapped by the provided `crs` until the first cartesian one (i.e. the first for which [`iscartesiancrs`](@ref) returns `true`) is found, and then return it.
"""
function cartesiancrs(crs::AbstractCRS)
    iscartesiancrs(crs) && return crs
    linked = linkedcrs(crs)
    return cartesiancrs(linked)
end
cartesiancrs(coord::FieldOrCoordinate) = crs(coord) |> cartesiancrs

"""
    basecrs(crs::AbstractCRS)
    basecrs(coord::FieldOrCoordinate)

Return the base CRS of the provided `crs`.

For most of the CRSs, this will simply return the crs itself. However, this is useful in the case of the [`AffineLinkedCRS`](@ref) which holds a base CRS and another CRS that is linked to the base one via an affine transformation.

All function checking a certain trait over an arbitrary CRS instance should use this function to first eventually unwrap the base CRS from its container.

As an example, if one wants to check whether a certain CRS instance is cartesian, one should write `iscartesiancrs(basecrs(crs))` instead of `iscartesiancrs(crs)`.
"""
basecrs(crs::AbstractCRS) = return crs
basecrs(coord::FieldOrCoordinate) = return crs(coord) |> basecrs