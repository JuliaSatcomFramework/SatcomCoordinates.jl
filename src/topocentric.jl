abstract type AbstractTopocentricCRS{CRS <: AbstractCRS, T} <: AbstractLinkedCRS{CRS} end

for CRS in (:NED, :ENU)
    @eval struct $CRS{CRS <: AbstractCRS, T} <: AbstractTopocentricCRS{CRS, T}
        crs::CRS
        ecef::Coordinate{CRS, T, 3}
        lla::Coordinate{LLA{CRS}, T, 3}
        rot::RotMatrix3{T}
        function $CRS(crs::CRS, ecef::Coordinate{CRS, T, 3}, lla::Coordinate{LLA{CRS}, T, 3}, rot::RotMatrix3{T}) where {CRS <: AbstractCRS, T}
            isecefcrs(basecrs(crs)) || throw(ArgumentError("The $CRS CRS must be associated with an ECEF CRS. The provided CRS is $(basetype(crs)) which is not an ECEF one."))
            return new{CRS, T}(crs, ecef, lla, rot)
        end
    end
end

@define_properties NED [
    n => u"m" => (north, x)
    e => u"m" => (east, y)
    d => u"m" => (down, z)
]

@define_properties ENU [
    e => u"m" => (east, x)
    n => u"m" => (north, y)
    u => u"m" => (up, z)
]

BasicTypes.valuetype(::Type{<:AbstractTopocentricCRS{<:Any, T}}) where T = T
function BasicTypes.change_valuetype(::Type{T}, topo_crs::AbstractTopocentricCRS) where T <: AbstractFloat
    crs = change_valuetype(T, topo_crs.crs)
    ecef = change_valuetype(T, topo_crs.ecef)
    lla = change_valuetype(T, topo_crs.lla)
    rot = RotMatrix3{T}(topo_crs.rot)
    return basetype(topo_crs)(crs, ecef, lla, rot)
end

# We need to overload this as by default the `is_same_crs` function checks if the CRS are the same type. This works for most types as all the identifying characteristics are in the type domain. This is not the case for subtypes as they store the origin and rotation as fields.
is_same_crs(crs1::CRS, crs2::CRS) where CRS <: AbstractTopocentricCRS = crs1 == crs2

# Constructors
function (::Type{TOPO})(crs::CRS, ecef::Coordinate{CRS, T, 3}, lla::Coordinate{LLA{CRS}, T, 3}) where {TOPO <: AbstractTopocentricCRS, CRS <: AbstractCRS, T <: AbstractFloat}
    (; lat, lon) = Raw(lla)
    C = basetype(TOPO)
    R = _topocentric_rotation(C, lat, lon)
    return C(crs, ecef, lla, R)
end
function (::Type{TOPO})(origin::Coordinate) where {TOPO <: AbstractTopocentricCRS}
    base = basecrs(origin)
    C = basetype(TOPO)
    if isecefcrs(base)
        ecefcrs = crs(origin)
        ecef = origin
        lla = change_crs(LLA(ecefcrs), ecef)
        return C(ecefcrs, ecef, lla)
    elseif isllacrs(base)
        ecefcrs = linkedcrs(crs(origin))
        lla = origin
        ecef = change_crs(ecefcrs, lla)
        return C(ecefcrs, ecef, lla)
    else
        throw(ArgumentError("The origin of the $C CRS must be associated with an ECEF or LLA CRS. The provided origin is $(basetype(crs(origin))) which is not an ECEF or LLA one."))
    end
end

function _topocentric_rotation(::Type{CRS}, lat::T, lon::T) where CRS <: Union{NED, ENU} where T <: AbstractFloat
    # We express the unit versor of the ENU coordinate system as function of lat lon
    sλ, cλ = sincos(lon)
    sφ, cφ = sincos(lat)
    n̂ = SVector{3,T}(-cλ*sφ, -sλ*sφ, cφ)
    ê = SVector{3,T}(-sλ, cλ, 0)
    d̂ = SVector{3,T}(-cλ*cφ, -sλ*cφ, -sφ)
    if CRS <: NED
        return RotMatrix3{T}(hcat(n̂, ê, d̂))
    else
        return RotMatrix3{T}(hcat(ê, n̂, -d̂))
    end
end

#### Transformations ####
function raw_linkedcrs_transform(crs::AbstractTopocentricCRS)
    translation = tuplecoords(crs.ecef)
    rotation = crs.rot
    return RawAffineTransform(rotation, translation)
end

have_same_origin(crs1::AbstractTopocentricCRS, crs2::AbstractTopocentricCRS) = false
have_same_origin(crs1::AbstractTopocentricCRS{CRS}, crs2::AbstractTopocentricCRS{CRS}) where CRS <: AbstractCRS = crs1.ecef == crs2.ecef

_different_origin_error(crs1::AbstractTopocentricCRS, crs2::AbstractTopocentricCRS) = throw(ArgumentError("The two provided Topocentric CRSs have different origins."))
_different_linkedcrs_error(crs1::AbstractTopocentricCRS, crs2::AbstractTopocentricCRS) = throw(ArgumentError("The two provided Topocentric CRSs are based on different linked CRSs."))

function transform_tuplecoords(crsₒ::NED{CRS}, crsᵢ::ENU{CRS}, tup::NTuple{3, <:AbstractFloat}) where CRS <: AbstractCRS
    is_same_crs(linkedcrs(crsₒ), linkedcrs(crsᵢ)) || _different_linkedcrs_error(crsₒ, crsᵢ)
    have_same_origin(crsₒ, crsᵢ) || _different_origin_error(crsₒ, crsᵢ)
    # We extract the basis of the ENU frame from the rotation matrix
    e, n, u = tup
    return (n, e, -u)
end
function transform_tuplecoords(crsₒ::ENU{CRS}, crsᵢ::NED{CRS}, tup::NTuple{3, <:AbstractFloat}) where CRS <: AbstractCRS
    is_same_crs(linkedcrs(crsₒ), linkedcrs(crsᵢ)) || _different_linkedcrs_error(crsₒ, crsᵢ)
    have_same_origin(crsₒ, crsᵢ) || _different_origin_error(crsₒ, crsᵢ)
    # We extract the basis of the NED frame from the rotation matrix
    n, e, d = tup
    return (e, n, -d)
end