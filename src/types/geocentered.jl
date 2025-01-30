struct ECEF{T} <: LengthCartesian{T, 3}
    x::Met{T}
    y::Met{T}
    z::Met{T}

    BasicTypes.constructor_without_checks(::Type{ECEF{T}}, x, y, z) where T = new{T}(x, y, z)
end

struct ECI{T} <: LengthCartesian{T, 3}
    x::Met{T}
    y::Met{T}
    z::Met{T}

    BasicTypes.constructor_without_checks(::Type{ECI{T}}, x, y, z) where T = new{T}(x, y, z)
end

struct LLA{T} <: AngleAngleDistance{T}
    lat::Deg{T}
    lon::Deg{T}
    alt::Met{T}

    BasicTypes.constructor_without_checks(::Type{LLA{T}}, lat, lon, alt) where T = new{T}(lat, lon, alt)
end

const GeocenteredPosition{T} = Union{ECEF{T}, ECI{T}, LLA{T}}