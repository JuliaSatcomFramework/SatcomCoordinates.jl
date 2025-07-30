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

Additionally, for each CRS whose type parameters can be completely identified by their fields, only one inner constructor without explicit type parameters should be defined.
.
"""
abstract type AbstractCRS end

"""
    AbstractLinkedCRS{CRS <: AbstractCRS} <: AbstractCRS

Abstract type representing a CRS that is linked to another CRS.

Each instance of a concrete subtype of `AbstractLinkedCRS` should have at least one field whose type subtypes `AbstractCRS`. 

The first field represents an `AbstractCRS` is automatically returned by the `[linkedcrs](@ref)(crs::AbstractLinkedCRS)` function.

"""
abstract type AbstractLinkedCRS{CRS <: AbstractCRS} <: AbstractCRS end

"""
    AbstractPointingCRS{CRS <: AbstractCRS} <: AbstractCRS

Abstract type representing any pointing type defined over a 3D Cartesian CRS.
Different pointing types identify different ways of identifying a position on the unitary sphere (over the specified CRS)

Although these are not strictly speaking CRSs themselves, they are considered a subtype of `AbstractCRS` to better fit within the package interface.

See also: [`AbstractCRS`](@ref), [`AngularPointingCRS`](@ref)
"""
abstract type AbstractPointingCRS{CRS <: AbstractCRS} <: AbstractLinkedCRS{CRS} end

"""
    Abstract2DPointingCRS{CRS <: AbstractCRS} <: AbstractPointingCRS{CRS}

Abstract type representing any pointing type defined over a 3D Cartesian CRS that is defined by two coordinates (e.g. theta/phi, azimuth/elevation, etc.).

See also: [`AbstractPointingCRS`](@ref), [`UV`](@ref), [`ThetaPhi`](@ref), [`AzOverEl`](@ref), [`ElOverAz`](@ref), [`AzEl`](@ref)
"""
abstract type Abstract2DPointingCRS{CRS <: AbstractCRS} <: AbstractPointingCRS{CRS} end

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

"""
    AbstractRawCRSTransform <: Transform

Abstract type representing a **raw** transform between two CRSs. A **raw** transform is the lower level CRS transformation that operate directly on the raw coordinates of the two CRSs (i.e. the one returned by `tuplecoords(coords::Coordinate{CRS})`)

A **raw** transform is used inernally by the user-facing `AbstractCRSTransform` and is expected to receive as input a `NTuple{N, T <: AbstractFloat}` and produce as output a `NTuple{M, T <:AbstractFloat}`, where `N` and `M` are the number of coordinates (i.e. the output of `ncoords(crs)`) of the input and output CRSs respectively.

See extended help for more details on necessary methods for new concrete subtypes of `AbstractRawCRSTransform`.

# Extended Help

Each new concrete subtype of `AbstractRawCRSTransform` (indicated with type name `RAW_T` in the rest of this section) is expected to implement a method for the following two methods:
- `ncoords_out(::Type{<:RAW_T})`: Returns the number of coordinates in the output NTuple (i.e. the `M` above)
- `ncoords_in(::Type{<:RAW_T})`: Returns the number of coordinates in the input NTuple (i.e. the `N` above)

For transforms where `N === M`, it is sufficient to just implement `ncoords(::Type{<:RAW_T})` as that is the default fallback for both `ncoords_out` and `ncoords_in`.

Additionally, new Raw transforms must implement the appropriate interface functions from `TransformsBase.jl` which as a minimum requires a valid method for:
- `TransformsBase.apply(t::RAW_T, tup::NTuple{N, <:AbstractFloat}) where N`: Remember that this function must provide 2 separate outputs, the first is the actual transformed coordinate as `NTuple{M, <:AbstractFloat}` and the second is the `cache` output of the `TransformsBase` interface. For all expected subtypes of `AbstractRawCRSTransform`, this second output should simply be `nothing`.
"""
abstract type AbstractRawCRSTransform <: Transform end