##################################################################
########                 Type Definitions                 ########
##################################################################

"""
    Cartesian <: AbstractCRS

Generic Cartesian CRS, for use in cases that do not require any specific identification of a CRS/Position
"""
struct Cartesian <: AbstractCRS end

##################################################################
########                 CRS Properties                  #########
##################################################################

# Have cartesian CRSs standard properties and units by default
@define_properties AbstractCRS [
    x => u"m"
    y => u"m"
    z => u"m"
]


#### AffineCartesian ####

"""
    AffineCartesian{CRSₗ, CRS, T} <: AbstractLinkedCRS{CRS}

A Cartesian CRS that is linked to another Cartesian CRS through a user-defined affine transform.

# Fields
- `linked::CRSₗ <: AbstractCRS`: The linked CRS
- `base::CRS <: AbstractCRS`: The base CRS
- `transform::T <: RawAffineTransform`: The affine transform that links the base CRS to the linked CRS

The two CRSs used to define the AffineLinkedCRS instance must be Cartesian CRSs (i.e. they must have `iscartesiancrs(crs) == true`).

For linking a non-cartesian base CRS, simply use the `AffineCartesian` as the base for further nesting. As an example, if one desires to use an `LLA` CRS as the base for an `AffineCartesian` CRS, simply create an `AffineCartesian` CRS with the underlying `ECEF` CRS and use that for wrapping the `LLA` CRS.
"""
struct AffineCartesian{CRSₗ <: AbstractCRS, CRS <: AbstractCRS, T <: RawAffineTransform} <: AbstractLinkedCRS{CRSₗ}
    linked::CRSₗ
    base::CRS
    transform::T
    function AffineCartesian(linked::CRSₗ, base::CRS, transform::T) where {CRSₗ <: AbstractCRS, CRS <: AbstractCRS, T <: RawAffineTransform}
        iscartesian = hascrstrait(cartesiancrs)
        isroot = hascrstrait(rootcrs)
        if !iscartesian(linked) || !iscartesian(base)
            throw(ArgumentError("The two CRSs used to define the AffineCartesian instance must be Cartesian CRSs (i.e. they must have `hascrstrait(cartesiancrs, crs) == true`)."))
        end
        isroot(base) || throw(ArgumentError("The base CRS of an AffineCartesian CRS must be a root CRS (i.e. it must have `hascrstrait(rootcrs, crs) == true`)."))
        ncoords(linked) == ncoords(base) == ncoords(transform) || throw(ArgumentError("The number of dimensions of the linked CRS, base CRS and provided transform must be the same."))
        return new{CRSₗ, CRS, T}(linked, base, transform)
    end
end

# With this function we forward all trait checks to the base CRS
crsfield(::typeof(traitcrs), ::Type{<:AffineCartesian}) = :base

function is_same_crs(crs1::CRS, crs2::CRS) where {CRS <: AffineCartesian}
    is_same_crs(crs1.linked, crs2.linked) || return false
    is_same_crs(crs1.base, crs2.base) || return false
    return crs1.transform == crs2.transform
end

@define_properties AffineCartesian [
    getcrstype(traitcrs, _)...
]

# Simply give the stored transform
raw_linkedcrs_transform(crs::AffineCartesian) = crs.transform

##### Base.show #####
function PlutoShowHelpers.repl_summary(c::AffineCartesian)
    string(
        PlutoShowHelpers.shortname(c), 
        "{",
        PlutoShowHelpers.shortname(getcrs(linkedcrs, c)),
        ", ",
        PlutoShowHelpers.shortname(getcrs(traitcrs, c)),
        "}"
    )
end