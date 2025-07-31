# Helper function to find how many fields which subtype AbstractCRS a specific CRS type has
nlinked_crs(C::Type{<:AbstractCRS}) = count(T -> T <: AbstractCRS, fieldtypes(C))

"""
    isrootcrs(C::Type{<:AbstractCRS})
    isrootcrs(crs::AbstractCRS)

Return `true` if the CRS `C` is a root CRS, `false` otherwise.

A root CRS is a CRS which is not derived or linked to any other CRS.

All root CRSs should also be cartesian CRSs

See also: [`rootcrs`](@ref), [`iscartesiancrs`](@ref), [`isderivedcrs`](@ref), []
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
    if isrootcrs(linked)
        return linked
    else
        return rootcrs(linked)
    end
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
    isderivedcrs(C::Type{<:AbstractCRS})
    isderivedcrs(crs::AbstractCRS)

Return `true` if the CRS `C` is derived from another CRS, `false` otherwise.

The difference between a **derived CRS** and a **linked CRS** is that the former can only be defined on top of its linked CRS, the latter is instead encompassing all CRSs which are linked to (at least) one other CRS.

An example of a **derived CRS** is the `LLA` CRS which is only defined on top of an `ECEF` CRS.

An example of a **linked CRS** which is not also a **derived CRS** is a Cartesian CRS which is referenced to another Cartesian CRS via a user-defined affine transformation.

By default, this function returns `true` if the CRS has exactly one field which is a subtype of `AbstractCRS`, `false` otherwise.

See also: [`linkedcrs`](@ref), [`islinkedcrs`](@ref)
"""
isderivedcrs(::Type{C}) where {C<:AbstractCRS} = nlinked_crs(C) == 1
isderivedcrs(crs::AbstractCRS) = isderivedcrs(typeof(crs))

"""
    iscartesiancrs(C::Type{<:AbstractCRS})
    iscartesiancrs(crs::AbstractCRS)

Return `true` if the CRS `C` is a Cartesian CRS, `false` otherwise.

The default implementation assumes a CRS is cartesian if it has 3 dimensions and all of them have units of length.

See also: [`cartesiancrs`](@ref), [`isderivedcrs`](@ref), [`islinkedcrs`](@ref)
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
    if iscartesiancrs(linked)
        return linked
    else
        return cartesiancrs(wrapped)
    end
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

"""
    isecefcrs(CRS::Type{<:AbstractCRS})
    isecefcrs(crs::AbstractCRS)

Return `true` if the provided CRS `crs` (or CRS type `CRS`) is an Ellipsoide-Centered-Ellipsoid-Fixed (ECEF) one.
""" 
isecefcrs(::Type{<:AbstractCRS}) = false
isecefcrs(::Type{<:ECEF}) = true
isecefcrs(crs::AbstractCRS) = isecefcrs(typeof(crs))

"""
    istopocentriccrs(CRS::Type{<:AbstractCRS})
    istopocentriccrs(crs::AbstractCRS)

Return `true` if the provided CRS `crs` (or CRS type `CRS`) is a topocentric CRS.
"""
istopocentriccrs(::Type{<:AbstractCRS}) = false
istopocentriccrs(::Type{<:AbstractTopocentricCRS}) = true
istopocentriccrs(crs::AbstractCRS) = istopocentriccrs(typeof(crs))

"""
    isllacrs(CRS::Type{<:AbstractCRS})
    isllacrs(crs::AbstractCRS)

Return `true` if the provided CRS `crs` (or CRS type `CRS`) is a Local Level Angle (LLA) CRS.
"""
isllacrs(::Type{<:AbstractCRS}) = false
isllacrs(::Type{<:LLA}) = true
isllacrs(crs::AbstractCRS) = isllacrs(typeof(crs))

####### Transform traits #######

"""
    isaffinetransform(t::Transform)
    isaffinetransform(t::Type{<:Transform})

Function that returns true if the transform is an affine transform, meaning that it is a composition of a rotation and a translation.

Any transform which is considered **affine** should have a valid method for the following two functions:
- `SatcomCoordinates.raw_rotation(t::Transform)`: Returns the rotation matrix associated to `t` as a `RotMatrix`
- `SatcomCoordinates.raw_translation(t::Transform)`: Returns the translation vector associated to `t` as a `SVector`
"""
isaffinetransform(::Type{<:RawAffineTransform}) = true
isaffinetransform(::Type{<:Transform}) = false
isaffinetransform(t::Transform) = isaffinetransform(typeof(t))

"""
    israwtransform(t::Transform)
    israwtransform(t::Type{<:Transform})

Function that returns true if the transform is considered **raw**, meaning that it directy operates and returns raw vectors or NTuples without units and is not specifically tied to input and output CRSs.

Raw transforms are supposed to be internally used as fields to build concrete subtypes of `AbstractCRSTransform`.

See [`CRSTransform`](@ref) for an example of the only concrete subtype implemented in this package.
"""
israwtransform(::Type{<:Transform}) = true
israwtransform(t::Transform) = israwtransform(typeof(t))
israwtransform(::Type{<:AbstractCRSTransform}) = false