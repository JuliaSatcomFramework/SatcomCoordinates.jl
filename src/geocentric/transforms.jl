#### Transformation between ECI and ECEF ####

"""
    eci_to_ecef_rotation(eci_id, ecef_id; kwargs...)

This function is expected to return the rotation matrix that transforms ECI coordinates into ECEF coordinates.

!!! note "Returned Matrix"
    The returned matrix is automatically converted to `Rotations.RotMatrix3` so the ouptut of this should either by already a `RotMatrix3` or something that can be implicitly converted to it..

This function is called when trying to transform between ECI and ECEF coordinates.

Any translation between ECI and ECEF coordinates will extract the rotation matrix by calling this function with the `id` of the ECI and ECEF frames respectively and then simply apply it to the raw tuple coordinates (directly from ECI to ECEF, inverting the matrix before for ECEF to ECI)

All the auxiliary data required to compute the rotation matrix shall be provided via keyword arguments which are simply propagated from the `change_crs` call (and via the lower_level `transform_tuplecoords` one).
"""
function eci_to_ecef_rotation end


"""
    transform_tuplecoords(ecef_crs::ECEF, eci_crs::ECI, tup::NTuple{3,T}; R_eci_to_ecef = NotProvided(), kwargs...) where T<:AbstractFloat
    transform_tuplecoords(eci_crs::ECI, ecef_crs::ECEF, tup::NTuple{3,T}; R_eci_to_ecef = NotProvided(), kwargs...) where T<:AbstractFloat

Transforms a tuple of coordinates between an ECEF and ECI CRS. If the rotation matrix to go from the specific ECI CRS to the ECEF CRS is explicitly provided via the `R_eci_to_ecef` keyword argument, it will be used to directly transform the coordinates. Otherwise, the [`eci_to_ecef_rotation`](@ref) function will be used to compute it using the `frameid` of both ECI and ECEF CRSs.
"""
function transform_tuplecoords(eci_crs::ECI, ecef_crs::ECEF, tup::NTuple{3,T}; R_eci_to_ecef = NotProvided(), kwargs...) where T<:AbstractFloat
    eci_id = frameid(eci_crs)
    ecef_id = frameid(ecef_crs)
    R = @fallback(R_eci_to_ecef, eci_to_ecef_rotation(eci_id, ecef_id; kwargs...)) |> RotMatrix3{T}
    newv = R' * SVector{3, T}(tup)
    return Tuple(newv)
end
function transform_tuplecoords(ecef_crs::ECEF, eci_crs::ECI, tup::NTuple{3,T}; R_eci_to_ecef = NotProvided(), kwargs...) where T<:AbstractFloat
    ecef_id = frameid(ecef_crs)
    eci_id = frameid(eci_crs)
    R = @fallback(R_eci_to_ecef, eci_to_ecef_rotation(eci_id, ecef_id; kwargs...)) |> RotMatrix3{T}
    newv = R * SVector{3, T}(tup)
    return Tuple(newv)
end


#### Transformation between ECEF and LLA ####
abstract type LLATransform <: AbstractRawCRSTransform end
struct ECEFtoLLA{ID} <: LLATransform
    id::ID
end
struct LLAtoECEF{ID} <: LLATransform
    id::ID
end

ellipsoidparams(t::LLATransform) = ellipsoidparams(t.id)

TransformsBase.parameters(t::LLATransform) = (t.id,)
TransformsBase.isinvertible(::Type{<:LLATransform}) = true
TransformsBase.isrevertible(::Type{<:LLATransform}) = true

ncoords(::Type{<:LLATransform}) = 3

TransformsBase.inverse(t::ECEFtoLLA) = LLAtoECEF(t.id)
TransformsBase.inverse(t::LLAtoECEF) = ECEFtoLLA(t.id)

### Transformation
function raw_linkedcrs_transform(crs::LLA)
    ecefcrs = linkedcrs(crs)
    raw = LLAtoECEF(frameid(ecefcrs))
    return raw
end