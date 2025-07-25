"""
    AbstractCRS

Abstract type representing an arbitrary coordinate reference system. This is intended to be used as type parameter for all coordinate types to allow consistency check between operation among coordinates and in some cases simplify conversion of a given coordinate to different CRSs.

All concrete subtypes of `AbstractCRS` are expected to either by directly a 3-dimensional cartesian CRS (i.e. a subtype of `AbstractCartesianCRS`) or be based on a 3-dimensional cartesian CRS.

The reference 3-dimensional cartesian CRS should always be accessible from any custom subtype of `AbstractCRS` via the [`cartesian_crs`](@ref) function.
"""
abstract type AbstractCRS end

"""
    AbstractCartesianCRS <: AbstractCRS

Abstract type representing a Cartesian CRS. A 3-dimensional cartesian CRS is expected to be the basis of any other custom CRS and is used internally to check whether coordinates refer to compatible CRSs.
"""
abstract type AbstractCartesianCRS <: AbstractCRS end

"""
    AbstractEllipsoidCentricCRS <: AbstractCartesianCRS

Abstract type representing a 3D Cartesian CRS whose origin is at the center of a reference ellipsoid.

Examples of such a CRS are the ECEF and ECI CRSs.
"""
abstract type AbstractEllipsoidCentricCRS <: AbstractCartesianCRS end

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
abstract type FieldOrCoordinate end

"""
    AbstractSatcomCoordinate{CRS <: AbstractCRS, T, N}

General abstract type identifying a _coordinate_ with `N` dimension and defined with respect to a specific Coordinate Reference System `CRS`. The parameter `T` represent the underlying numeric type (e.g. machine precision) of the coordinate components.

!!! note
    The term _coordinate_ is used here in a loose sense, identifying both position in space as well as pointing directions
"""
abstract type AbstractSatcomCoordinate{CRS <: AbstractCRS, T, N} <: FieldOrCoordinate end

"""
    AbstractCRSTransform{T}

Abstract type representing a coordinate transform between two CRSs with numbertype `T`.
"""
abstract type AbstractCRSTransform{T} <: Transform end

"""
    AbstractAffineCRSTransform{T}

Abstract type representing an affine transform between two CRSs with numbertype `T`.
"""
abstract type AbstractAffineCRSTransform{T} <: AbstractCRSTransform{T} end