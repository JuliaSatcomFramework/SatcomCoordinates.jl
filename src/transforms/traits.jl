
####### Transform traits #######

"""
    isaffinetransform(t::Transform)
    isaffinetransform(t::Type{<:Transform})

Function that returns true if the transform is an affine transform, meaning that it is a composition of a rotation and a translation.

Any transform which is considered **affine** should have a valid method for the following two functions:
- `SatcomCoordinates.raw_rotation(t::Transform)`: Returns the rotation matrix associated to `t` as a `RotMatrix`
- `SatcomCoordinates.raw_translation(t::Transform)`: Returns the translation vector associated to `t` as a `SVector`
"""
isaffinetransform(::Type{<:RawAffineTransform}) = return true
isaffinetransform(::Type{<:Transform}) = return false
isaffinetransform(t::Transform) = return isaffinetransform(typeof(t))

"""
    israwtransform(t::Transform)
    israwtransform(t::Type{<:Transform})

Function that returns true if the transform is considered **raw**, meaning that it directy operates and returns raw vectors or NTuples without units and is not specifically tied to input and output CRSs.

Raw transforms are supposed to be internally used as fields to build concrete subtypes of `AbstractCRSTransform`.

!!! note "Expected Input/Output" 
    Raw transforms are always assumed to get a `NTuple` of floating numbers as input and produce a `NTuple` of floating numbers as output.

See [`CRSTransform`](@ref) for an example of the only concrete subtype implemented in this package.
"""
israwtransform(::Type{<:Transform}) = return true
israwtransform(::Type{<:AbstractCRSTransform}) = return false
israwtransform(t::Transform) = return israwtransform(typeof(t))