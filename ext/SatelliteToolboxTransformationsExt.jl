module SatelliteToolboxTransformationsExt

using SatelliteToolboxTransformations: SatelliteToolboxTransformations, ecef_to_geodetic, geodetic_to_ecef
using SatelliteToolboxBase: SatelliteToolboxBase, Ellipsoid, WGS84_ELLIPSOID
using SatcomCoordinates: SatcomCoordinates, change_numbertype, raw_nt, constructor_without_checks, to_svector, asdeg, to_meters, ECEF, LLA

function SatelliteToolboxTransformations.ecef_to_geodetic(ecef::ECEF{T}; ellipsoid::Ellipsoid=WGS84_ELLIPSOID) where T <: AbstractFloat 
    ellipsoid = change_numbertype(T, ellipsoid)
    lat,lon,alt = ecef_to_geodetic(to_svector(ecef); ellipsoid)
    return constructor_without_checks(LLA{T}, asdeg(lat), asdeg(lon), to_meters(alt))
end

function SatelliteToolboxTransformations.geodetic_to_ecef(lla::LLA{T}; ellipsoid::Ellipsoid=WGS84_ELLIPSOID) where T
    ellipsoid = change_numbertype(T, ellipsoid)
	(;lat, lon, alt) = raw_nt(lla)
    ecef = geodetic_to_ecef(lat,lon,alt;ellipsoid) |> ECEF
    return ecef
end

end