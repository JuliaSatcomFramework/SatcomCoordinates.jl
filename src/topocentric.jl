abstract type AbstractTopocentricCRS{CRS <: AbstractCRS, T} <: AbstractCRS end

struct NED{CRS <: AbstractCRS, T} <: AbstractTopocentricCRS{CRS, T}
    crs::CRS
    ecef::Coordinate{CRS, T, 3}
    lla::Coordinate{LLA{CRS}, T, 3}
    rot::RotMatrix3{T}
    function NED(crs::CRS, ecef::Coordinate{CRS, T, 3}, lla::Coordinate{LLA{CRS}, T, 3}, rot::RotMatrix3{T}) where {CRS <: AbstractCRS, T}
        apply_crs_predicate(crs, isecefcrs) || throw(ArgumentError("The NED CRS must be associated with an ECEF CRS. The provided CRS is $(basetype(crs)) which is not an ECEF one."))
        return new{CRS, T}(crs, ecef, lla, rot)
    end
end

@define_properties NED [
    n => u"m" => (north, x)
    e => u"m" => (east, y)
    d => u"m" => (down, z)
]

# Constructors
function NED(crs::CRS, ecef::Coordinate{CRS, T, 3}, lla::Coordinate{LLA{CRS}, T, 3}) where {CRS <: AbstractCRS, T <: AbstractFloat}
    (; lat, lon) = Raw(lla)
    # We express the unit versor of the ENU coordinate system as function of lat lon
    sλ, cλ = sincos(lon)
    sφ, cφ = sincos(lat)
    n̂ = SVector{3,T}(-cλ*sφ, -sλ*sφ, cφ)
    ê = SVector{3,T}(-sλ, cλ, 0)
    d̂ = SVector{3,T}(-cλ*cφ, -sλ*cφ, -sφ)
    R = RotMatrix3{T}(hcat(n̂, ê, d̂))
    return NED(crs, ecef, lla, R)
end
function NED(origin::Coordinate)
    _crs = crs(origin)
    if apply_crs_predicate(_crs, isecefcrs)
        ecefcrs = _crs
        ecef = origin
        lla = change_crs(LLA(ecefcrs), ecef)
        return NED(ecefcrs, ecef, lla)
    elseif apply_crs_predicate(_crs, c -> c isa LLA)
        ecefcrs = wrappedcrs(_crs)
        lla = origin
        ecef = change_crs(ecefcrs, lla)
        return NED(ecefcrs, ecef, lla)
    else
        throw(ArgumentError("The origin of the NED CRS must be associated with an ECEF or LLA CRS. The provided origin is $(basetype(_crs)) which is not an ECEF or LLA one."))
    end
end