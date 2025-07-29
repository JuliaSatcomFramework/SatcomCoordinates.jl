"""
    AbstractCRS

Abstract type representing an arbitrary coordinate reference system. This is intended to be used as type parameter for all coordinate types to allow consistency check between operation among coordinates and in some cases simplify conversion of a given coordinate to different CRSs.

All concrete subtypes of `AbstractCRS` are expected to either by directly a 3-dimensional cartesian CRS (i.e. CRS whose units are all lengths) or be based on a 3-dimensional cartesian CRS.

The reference 3-dimensional cartesian CRS should always be accessible from any custom subtype of `AbstractCRS` via the [`cartesiancrs`](@ref) function.

By default, a CRS is considered cartesian if all its properties have units of length. Specific customization of whether a custom CRS is considered or not cartesian can be done by adding a custom method to the `iscartesiancrs` function (which must return either `true` or `false`).

!!! note "No-Argument Constructor"
    Each concrete subtype of `AbstractCRS` is expected to define a no-argument constructor without any type parameter (i.e. `CRS()`) which returns the default instance of said CRS.

# Extended Help

A subtype of an `AbstractCRS` shall satisfy the following conditions:
- It can be cartesian or not cartesian (and should have a valid method for [`iscartesiancrs`](@ref) representing this)
- It can be a root crs, or a derived crs. In the latter case, it should have the wrapped CRS type as it's first type parameter, and contain the specific instance of the wrapped CRS as a field within it.
  - Derived CRSs should only depend on a single wrapped CRS. Complex derivations shall be implemented by nesting CRSs rather than by having multiple different wrapped CRSs as fields.
  - Derived CRSs should be wrapping a Cartesian CRS. Any kind of -non-cartesian CRS shall only be the last level of nesting.
- Derived CRSs shall have a valid method for the `to_wrappedcrs` function, which should return a transformation to express a coordinate in the derived CRS to the equivalent ones expressed in the wrapped CRS.
.
"""
abstract type AbstractCRS end

"""
    AbstractPointingCRS{CRS <: AbstractCRS} <: AbstractCRS

Abstract type representing any pointing type defined over a 3D Cartesian CRS.
Different pointing types identify different ways of identifying a position on the unitary sphere (over the specified CRS) with two coordinates (e.g. theta/phi, azimuth/elevation, etc.)

Although these are not strictly speaking CRSs themselves, they are considered a subtype of `AbstractCRS` to better fit within the package interface.

See also: [`AbstractCRS`](@ref), [`UV`](@ref), [`ThetaPhi`](@ref), [`AzOverEl`](@ref), [`ElOverAz`](@ref), [`AzEl`](@ref)
"""
abstract type AbstractPointingCRS{CRS <: AbstractCRS} <: AbstractCRS end

"""
    AbstractEllipsoidCentricCRS <: AbstractCRS

Abstract type representing a 3D Cartesian CRS whose origin is at the center of a reference ellipsoid.

Examples of such a CRS are the ECEF and ECI CRSs.
"""
abstract type AbstractEllipsoidCentricCRS <: AbstractCRS end

"""
    AbstractEllipsoidFixedCRS <: AbstractEllipsoidCentricCRS

Abstract type representing a 3D Cartesian CRS whose origin is at the center of a reference ellipsoid and whose axes are fixed with respect to the surface of the ellipsoid.

An example of such a CRS is the ECEF CRS.
"""
abstract type AbstractEllipsoidFixedCRS <: AbstractEllipsoidCentricCRS end

"""
    AbstractEllipsoidIntertialCRS <: AbstractEllipsoidCentricCRS

Abstract type representing a 3D Cartesian CRS whose origin is at the center of a reference ellipsoid and whose axes are _inertial_ (i.e. not accelerating) with respect to the stars.

An example of such a CRS is the ECI CRS.
"""
abstract type AbstractEllipsoidIntertialCRS <: AbstractEllipsoidCentricCRS end

"""
    abstract type FieldOrCoordinate end

Abstract type representing either a field or a coordinate.

This is wrap all possible types within this package that are not CRSs themselves. It is used to contraint custom methods we have for `Base` functions.
"""
abstract type FieldOrCoordinate{CRS <: AbstractCRS} end

"""
    AbstractSatcomCoordinate{CRS <: AbstractCRS, T, N}

General abstract type identifying a _coordinate_ with `N` dimension and defined with respect to a specific Coordinate Reference System `CRS`. The parameter `T` represent the underlying numeric type (e.g. machine precision) of the coordinate components.

!!! note
    The term _coordinate_ is used here in a loose sense, identifying both position in space as well as pointing directions
"""
abstract type AbstractSatcomCoordinate{CRS <: AbstractCRS, T, N} <: FieldOrCoordinate{CRS} end

"""
    AbstractCRSTransform

Abstract type representing a coordinate transform between two CRSs with numbertype `T`.
"""
abstract type AbstractCRSTransform{CRSₒ <: AbstractCRS, CRSᵢ <: AbstractCRS} <: Transform end