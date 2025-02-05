module CountriesBordersExt

using SatcomCoordinates: SatcomCoordinates, LLA, to_radians, to_meters, change_numbertype
using CountriesBorders: CountriesBorders, LatLon, DOMAIN, LATLON, CountryBorder, CoordRefSystems

function Base.convert(::Type{LATLON{T}}, lla::LLA) where T 
    (; lat, lon) = change_numbertype(T, lla)
    return LatLon(lat, lon)
end
Base.convert(::Type{LatLon}, lla::LLA) = convert(LATLON{Float32}, lla)

CoordRefSystems.LatLon(lla::LLA) = convert(LatLon, lla)

function Base.in(lla::LLA, region::Union{DOMAIN, CountryBorder})
    ll = convert(LatLon, lla)
    return ll in region
end

Base.convert(::Type{LLA}, ll::LATLON) = LLA(ll.lat, ll.lon, 0)
SatcomCoordinates.LLA(ll::LATLON) = convert(LLA, ll)

end