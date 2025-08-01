# Generics

Any valid CRS must be a subtype of `AbstractCRS`. For more complex CRSs that depend on (e.g. are defined upon) another CRS, it is advised to directly subtype `AbstractLinkedCRS` to already fallback to customized defaults.

The way CRSs are defined within this package is influenced by the following high level constraints/simplifications:
- All of the CRSs should either be Cartesian CRSs in 3 dimensions, or be defined over a Cartesian CRS in 3 dimensions
- All CRS must have specific units associated to each of their properties, and the number of properties of a CRS must be consistent with the number of coordinates/dimensions the CRS has (as per point above, most of the CRSs will have 3 dimensions but some, like pointing CRSs, only have 2 dimensions)
  - The specifics property names and units for the CRS's dimensions are defined via the [`SatcomCoordinates.units(CRS::Type{<:AbstractCRS})`](@ref) function. This function has a default fallbacks which defines properties and units for a standard Cartesian CRS, which implies:
    - `x` => u"m"`
    - `y` => u"m"`
    - `z` => u"m"`
- All CRSs which that depend on another CRS should contain an instance of the parent CRS as a field.
  - For most the derived CRS, complex/nested derivation should in most cases be implemented by nesting CRSs rather than by having multiple different wrapped CRSs as fields.

Apart from specific concrete types, CRSs properties are usually handled within the package by boolean _trait_ functions rather than by specific subtype hierarchies.

As an example, the following traits are used to differentiate between different types of CRSs:
- [`iscartesiancrs`](@ref)
- [`isrootcrs`](@ref)
- [`islinkedcrs`](@ref)

The three traits above are the basic ones. Additionally we have traits for identifying specific subkinds of CRSs in the following functions:
- `isecefcrs`
- `isecicrs`
- `isllacrs`
- `istopocentriccrs`

All of the above traits default to `false` for all CRSs except the corresponding ones defined within this package (e.g. `isecefcrs` defaults to `true` for `ECEF` CRSs).
New custom CRSs can simply define their specific trait if needed (e.g. defining a custom ECEF CRS without relying on the concrete `ECEF` type defined in this package).

## Expected methods/behavior of CRSs
All CRS types are expected to have an inner which does not take 