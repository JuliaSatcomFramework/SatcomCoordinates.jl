module SatcomCoordinatesSatelliteToolboxTransformationsExt

using SatelliteToolboxTransformations: SatelliteToolboxTransformations, ecef_to_geodetic, geodetic_to_ecef, r_eci_to_ecef, Ellipsoid
using SatcomCoordinates: SatcomCoordinates, ellipsoidparams, ECEFtoLLA, LLAtoECEF, EarthDefault
using SatcomCoordinates.TransformsBase: TransformsBase
using SatcomCoordinates.StaticArrays: SVector
using SatcomCoordinates.BasicTypes: Optional, NotProvided
using SatcomCoordinates.ConstructionBase: getproperties

SatcomCoordinates.ellipsoidparams(ell::Ellipsoid) = getproperties(ell)

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
function SatcomCoordinates.eci_to_ecef_rotation(eci_id::EarthDefault, ecef_id::EarthDefault; jd_utc, eci_frame = Val{:J2000}(), ecef_frame = Val{:ITRF}(), eop_data = NotProvided())
    if eop_data isa Optional{Nothing}
        if !applicable(r_eci_to_ecef, eci_frame, ecef_frame, jd_utc)
            throw(ArgumentError("The provided ECI ($(eci_frame)) and ECEF ($(ecef_frame)) frames require supplying the correct EOP data via the `eop_data` keyword argument."))
        end
        return r_eci_to_ecef(eci_frame, ecef_frame, jd_utc)
    else
        return r_eci_to_ecef(eci_frame, ecef_frame, jd_utc, eop_data)
    end
end

end
