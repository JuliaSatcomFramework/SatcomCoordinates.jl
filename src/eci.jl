"""
    ECI{ID} <: AbstractCRS

This represents an Ellipsoid-Centered Inertial (ECI) CRS which is uniquely identified by its only field `id::ID`.

This is a generalization of the conventianal **ECI** acronym which is only referred to earth-centered coordinates.

The `id` field can be any object that uniquely identifies a specific instance of ECI CRS

For conversion between coordinates in ECEF and ECI CRSs, the following method must also be implemented:
- `SatcomCoordinates.eci_to_ecef_rotation(eci_id::ID1, ecef_id::ID2; kwargs...)`
See its docstring for more details

When not specified, the default ID for ECEF CRSs is an instance of the singleton type [`DefaultEarthFrame`](@ref).

See also: [`ecefid`](@ref), [`ellipsoidparams`](@ref), [`DefaultEarthFrame`](@ref)
"""
struct ECI{ID} <: AbstractCRS
    id::ID
    # We only have a constructor without parameters specified
    ECI(id) = new{typeof(id)}(id)
end
ECI() = ECI(DefaultEarthFrame())

frameid(crs::ECI) = return crs.id

#### Transformation with ECI ####

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
    eci_to_ecef_rotation(eci_id::DefaultEarthFrame, ecef_id::DefaultEarthFrame; jd_utc, eci_frame, ecef_frame, eop_data)

Returns the rotation matrix that transforms coordinates from the ECI frame `eci_frame` to the ECEF frame `ecef_frame` at the given UTC Julian date `jd_utc`.

This function is the only implementation defined within the SatcomCoordinates package (via SatelliteToolboxTransformations extension) and relies on the `r_eci_to_ecef` function from the `SatelliteToolboxTransformations` package.

# Keyword Arguments
- `jd_utc`: The UTC Julian date at which the rotation matrix is computed. This keyword argument is required.
- `eci_frame`: The ECI frame to transform from. This keyword argument defults to `Val{:J2000}()`. Explicitly specify a different frame (among the ECI ones of SatelliteToolboxTransformations) if needed
- `ecef_frame`: The ECEF frame to transform to. This keyword argument defaults to `Val{:ITRF}()`. Explicitly specify a different frame (among the ECEF ones of SatelliteToolboxTransformations) if needed
- `eop_data`: The EOP data to use for the transformation. This defaults to use EOP 1980 data obtained with `SatelliteToolboxTransformations.fetch_iers_eop()`

See the docstring of [`eci_to_ecef_rotation`](@ref) for more details.
"""
function eci_to_ecef_rotation(eci_id::DefaultEarthFrame, ecef_id::DefaultEarthFrame; jd_utc, eci_frame = Val{:J2000}(), ecef_frame = Val{:ITRF}(), eop_data = NotProvided())
    if eop_data isa Optional{Nothing}
        if !applicable(r_eci_to_ecef, eci_frame, ecef_frame, jd_utc)
            throw(ArgumentError("The provided ECI ($(eci_frame)) and ECEF ($(ecef_frame)) frames require supplying the correct EOP data via the `eop_data` keyword argument."))
        end
        return r_eci_to_ecef(eci_frame, ecef_frame, jd_utc)
    else
        return r_eci_to_ecef(eci_frame, ecef_frame, jd_utc, eop_data)
    end
end

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