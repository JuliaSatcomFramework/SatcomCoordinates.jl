"""
    AffineLinkedCRS{CRSₗ, CRS, T} <: AbstractCRS

A CRS that is linked to another CRS through a user-defined affine transform.

# Fields
- `linked::CRSₗ`: The linked CRS
- `base::CRS`: The base CRS
- `transform::T`: The affine transform that links the base CRS to the linked CRS

The two CRSs used to define the AffineLinkedCRS instance must be Root Cartesian CRSs (i.e. they must have `isrootcrs(crs) && iscartesiancrs(crs) == true`).
"""
struct AffineLinkedCRS{CRSₗ <: AbstractCRS, CRS <: AbstractCRS, T <: RawAffineTransform} <: AbstractCRS
    linked::CRSₗ
    base::CRS
    transform::T
    function AffineLinkedCRS{CRSₗ, CRS, T}(linked::CRSₗ, base::CRS, transform::T) where {CRSₗ <: AbstractCRS, CRS <: AbstractCRS, T <: RawAffineTransform}
        if !all(crs -> isrootcrs(crs) && iscartesiancrs(crs), (linked, base))
            throw(ArgumentError("The two CRSs used to define the AffineLinkedCRS instance must be Root Cartesian CRSs (i.e. they must have `isrootcrs(crs) && iscartesiancrs(crs) == true`)."))
        end
        ncoords(linked) == ncoords(base) == ncoords(transform) || throw(ArgumentError("The number of dimensions of the linked CRS, base CRS and provided transform must be the same."))
        return new{CRSₗ, CRS, T}(linked, base, transform)
    end
end