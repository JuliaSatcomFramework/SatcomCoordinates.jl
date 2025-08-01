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
    eci_to_ecef_rotation(eci_id::EarthDefault, ecef_id::EarthDefault; jd_utc, eci_frame, ecef_frame, eop_data)

Returns the rotation matrix that transforms coordinates from the ECI frame `eci_frame` to the ECEF frame `ecef_frame` at the given UTC Julian date `jd_utc`.

This function is the only implementation defined within the SatcomCoordinates package (via SatelliteToolboxTransformations extension) and relies on the `r_eci_to_ecef` function from the `SatelliteToolboxTransformations` package.

# Keyword Arguments
- `jd_utc`: The UTC Julian date at which the rotation matrix is computed. This keyword argument is required.
- `eci_frame`: The ECI frame to transform from. This keyword argument defults to `Val{:J2000}()`. Explicitly specify a different frame (among the ECI ones of SatelliteToolboxTransformations) if needed
- `ecef_frame`: The ECEF frame to transform to. This keyword argument defaults to `Val{:ITRF}()`. Explicitly specify a different frame (among the ECEF ones of SatelliteToolboxTransformations) if needed
- `eop_data`: The EOP data to use for the transformation. This defaults to use EOP 1980 data obtained with `SatelliteToolboxTransformations.fetch_iers_eop()`

See the docstring of [`eci_to_ecef_rotation`](@ref) for more details.
"""
function eci_to_ecef_rotation(eci_id::EarthDefault, ecef_id::EarthDefault; jd_utc, eci_frame = Val{:J2000}(), ecef_frame = Val{:ITRF}(), eop_data = NotProvided())
    if eop_data isa Optional{Nothing}
        if !applicable(r_eci_to_ecef, eci_frame, ecef_frame, jd_utc)
            throw(ArgumentError("The provided ECI ($(eci_frame)) and ECEF ($(ecef_frame)) frames require supplying the correct EOP data via the `eop_data` keyword argument."))
        end
        return r_eci_to_ecef(eci_frame, ecef_frame, jd_utc)
    else
        return r_eci_to_ecef(eci_frame, ecef_frame, jd_utc, eop_data)
    end
end

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

function TransformsBase.apply(t::ECEFtoLLA, tup::NTuple{3,T}) where T<:AbstractFloat
    ellparams = ellipsoidparams(t)
    ellipsoid = Ellipsoid(NamedTuple{(:a, :f, :b, :e², :el²)}(ellparams)...)
    lat, lon, alt = ecef_to_geodetic(SVector(tup); ellipsoid)
    return map(T, (lat, lon, alt)), nothing
end

function TransformsBase.apply(t::LLAtoECEF, tup::NTuple{3,T}) where T<:AbstractFloat
    ellparams = ellipsoidparams(t)
    ellipsoid = Ellipsoid(NamedTuple{(:a, :f, :b, :e², :el²)}(ellparams)...)
    lat, lon, alt = tup
    x, y, z = geodetic_to_ecef(lat, lon, alt; ellipsoid)
    return map(T, (x, y, z)), nothing
end

ncoords(::Type{<:LLATransform}) = 3

TransformsBase.inverse(t::ECEFtoLLA) = LLAtoECEF(t.id)
TransformsBase.inverse(t::LLAtoECEF) = ECEFtoLLA(t.id)

### Transformation
function raw_linkedcrs_transform(crs::LLA)
    ecefcrs = linkedcrs(crs)
    raw = LLAtoECEF(frameid(ecefcrs))
    return raw
end