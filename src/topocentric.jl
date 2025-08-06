abstract type AbstractTopocentricCRS{CRS <: AbstractCRS, T} <: AbstractLinkedCRS{CRS} end

for CRS in (:NED, :ENU)
    @eval struct $CRS{CRS <: AbstractCRS, T} <: AbstractTopocentricCRS{CRS, T}
        crs::CRS
        ecef::Coordinate{CRS, T, 3}
        lla::Coordinate{LLA{CRS}, T, 3}
        rot::RotMatrix3{T}
        function $CRS(ecef_crs::CRS, ecef::Coordinate{CRS, T, 3}, lla::Coordinate{LLA_CRS, T, 3}, rot::RotMatrix3{T}) where {CRS <: AbstractCRS, LLA_CRS <: LLA{CRS}, T}
            hascrstrait(ecefcrs, ecef_crs) || throw(ArgumentError("The $CRS CRS must be associated with an ECEF CRS. The provided ECEF CRS is $(basetype(ecef_crs)) which is not an ECEF one."))
            is_same_crs(ecef_crs, getcrs(ecef)) || throw(ArgumentError("The `ecef` coordinate provided as second input does not seem to have the same CRS as the explicitly provided ECEF CRS `ecef_crs`."))
            hascrstrait(llacrs, getcrs(lla)) || throw(ArgumentError("The `lla` coordinate provided as third input does not seem to be based on an LLA CRS."))
            getcrs(linkedcrs, lla) == ecef_crs || throw(ArgumentError("The CRS of the `lla` coordinate provided as third input must be derived from the same ECEF CRS provided as first input."))
            return new{CRS, T}(ecef_crs, ecef, lla, rot)
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

"""
    topocrs

CRS Trait function to represent CRSs which are topocentric.
"""
topocrs(CRS::Type{<:AbstractTopocentricCRS}) = CRS

"""
    ecef_origin(crs::AbstractCRS)
    ecef_origin(obj::FieldOrCoordinate)

Return the coordinate (in ECEF CRS) of the origin of the provided `obj` or `crs`.

Custom topocentric CRSs must implement a specific method for this function.

For all other CRSs, this function will simply traverse the chaing of linked CRSs starting from `crs` until it either finds a valid topocentric CRS or it reaches the end of the chain (In which case it will simply throw an error).

See also [`lla_origin`](@ref)
"""
ecef_origin(crs::AbstractTopocentricCRS) = crs.ecef
function ecef_origin(crs::AbstractCRS)
    topo_crs = _recurse_crs(topocrs, crs)
    if !isvalidcrs(topo_crs)
        throw(ArgumentError("A topocentric CRS could not be found while traversing the linked CRS chain. So no ECEF origin could be extracted"))
    else
        return ecef_origin(topo_crs |> traitcrs) # We need to call `traitcrs` on the `topo_crs` as that may be a compound CRS that acts as ecefcrs by having a proxy for traits. This is the case for example for the AffineCartesian CRS.
    end
end
ecef_origin(obj::FieldOrCoordinate) = return ecef_origin(crs(obj))

"""
    lla_origin(crs::AbstractCRS)
    lla_origin(obj::FieldOrCoordinate)

Return the coordinate (in LLA CRS) of the origin of the provided `obj` or `crs`.

Custom topocentric CRSs must implement a specific method for this function.

For all other CRSs, this function will simply traverse the chaing of linked CRSs starting from `crs` until it either finds a valid topocentric CRS or it reaches the end of the chain (In which case it will simply throw an error).

See also [`ecef_origin`](@ref), [`AbstractTopocentricCRS`](@ref)
""" 
lla_origin(crs::AbstractTopocentricCRS) = crs.lla
function lla_origin(crs::AbstractCRS)
    topo_crs = _recurse_crs(topocrs, crs)
    if !isvalidcrs(topo_crs)
        throw(ArgumentError("A topocentric CRS could not be found while traversing the linked CRS chain. So no LLA origin could be extracted"))
    else
        return lla_origin(topo_crs |> traitcrs) # We need to call `traitcrs` on the `topo_crs` as that may be a compound CRS that acts as llacrs by having a proxy for traits. This is the case for example for the AffineCartesian CRS.
    end
end
lla_origin(obj::FieldOrCoordinate) = return lla_origin(crs(obj))

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
function (::Type{TOPO})(ecef_crs::CRS, ecef::Coordinate{CRS, T, 3}, lla::Coordinate{LLA_CRS, T, 3}) where {TOPO <: AbstractTopocentricCRS, CRS <: AbstractCRS, LLA_CRS <: AbstractCRS, T <: AbstractFloat}
    hascrstrait(llacrs, lla) || throw(ArgumentError("The `lla` coordinate provided as third input does not seem to be based on an LLA CRS."))
    (; lat, lon) = Raw(lla)
    C = basetype(TOPO)
    R = _topocentric_rotation(C, lat, lon)
    return C(ecef_crs, ecef, lla, R)
end
function (::Type{TOPO})(origin::Coordinate) where {TOPO <: AbstractTopocentricCRS}
    C = basetype(TOPO)
    if hascrstrait(ecefcrs, origin)
        ecef_crs = getcrs(origin)
        ecef = origin
        lla = change_crs(LLA(ecef_crs), ecef)
        return C(ecef_crs, ecef, lla)
    elseif hascrstrait(llacrs, origin)
        ecef_crs = getcrs(linkedcrs, origin)
        lla = origin
        ecef = change_crs(ecef_crs, lla)
        return C(ecef_crs, ecef, lla)
    else
        throw(ArgumentError("The origin of the $C CRS must be associated with an ECEF or LLA CRS. The provided origin's CRS is $(basetype(getcrs(origin))) which is not an ECEF or LLA one."))
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

have_same_origin(crs1::AbstractTopocentricCRS, crs2::AbstractTopocentricCRS) = return false
have_same_origin(crs1::AbstractTopocentricCRS{CRS}, crs2::AbstractTopocentricCRS{CRS}) where CRS <: AbstractCRS = return ecef_origin(crs1) == ecef_origin(crs2)

_different_origin_error(crs1::AbstractTopocentricCRS, crs2::AbstractTopocentricCRS) = throw(ArgumentError("The two provided Topocentric CRSs have different origins."))
_different_linkedcrs_error(crs1::AbstractTopocentricCRS, crs2::AbstractTopocentricCRS) = throw(ArgumentError("The two provided Topocentric CRSs are based on different linked CRSs."))

function transform_tuplecoords(crsₒ::NED{CRS}, crsᵢ::ENU{CRS}, tup::NTuple{3, <:AbstractFloat}) where CRS <: AbstractCRS
    is_same_crs(getcrs(linkedcrs, crsₒ), getcrs(linkedcrs, crsᵢ)) || _different_linkedcrs_error(crsₒ, crsᵢ)
    have_same_origin(crsₒ, crsᵢ) || _different_origin_error(crsₒ, crsᵢ)
    # We extract the basis of the ENU frame from the rotation matrix
    e, n, u = tup
    return (n, e, -u)
end
function transform_tuplecoords(crsₒ::ENU{CRS}, crsᵢ::NED{CRS}, tup::NTuple{3, <:AbstractFloat}) where CRS <: AbstractCRS
    is_same_crs(getcrs(linkedcrs, crsₒ), getcrs(linkedcrs, crsᵢ)) || _different_linkedcrs_error(crsₒ, crsᵢ)
    have_same_origin(crsₒ, crsᵢ) || _different_origin_error(crsₒ, crsᵢ)
    # We extract the basis of the NED frame from the rotation matrix
    n, e, d = tup
    return (e, n, -d)
end

#### NED Docstring ####
@doc """
    NED{CRS <: AbstractCRS, T} <: AbstractTopocentricCRS{CRS, T}

Represents a position in the North-East-Down (NED) coordinate system, which is a local coordinate system centered at a point on or above the surface of an Ellipsoid. 

This type stores inside of it it's origin (both in ECEF and LLA) as well as the rotation matrix to convert between a point from NED to it's linked ECEF CRS.

# Properties/Units/Aliases
- `n` => u"m" => (north, x)
- `e` => u"m" => (east, y)
- `d` => u"m" => (down, z)

# Constructor
    NED(origin::Coordinate)

Constructs a `NED` CRS by providing it's origin as Coordinate expressed either in an ECEF or LLA CRS.

# Convenience methods
Each custom CRS which satisfies the topocentric trait (for which `istopocentriccrs(crs) == true`) must implement the following methods:
- `ecef_origin(crs::CRS)`: This function shall return the coordinate (in the linked ECEF CRS) of the origin of the provided `crs`.
- `lla_origin(crs::CRS)`: This function shall return the coordinate (in the linked LLA CRS) of the origin of the provided `crs`.

# See also: [`istopocentriccrs`](@ref), [`ecef_origin`](@ref), [`lla_origin`](@ref), [`ENU`](@ref)
""" NED

@doc """
    ENU{CRS <: AbstractCRS, T} <: AbstractTopocentricCRS{CRS, T}

Represents a position in the East-North-Up (ENU) coordinate system, which is a local coordinate system centered at a point on or above the surface of an Ellipsoid. 

This type stores inside of it it's origin (both in ECEF and LLA) as well as the rotation matrix to convert between a point from ENU to it's linked ECEF CRS.

# Properties/Units/Aliases
- `e` => u"m" => (east, x)  
- `n` => u"m" => (north, y)
- `u` => u"m" => (up, z)

# Constructor
    ENU(origin::Coordinate)

Constructs a `ENU` CRS by providing it's origin as Coordinate expressed either in an ECEF or LLA CRS.

## Convenience methods
Each custom CRS which satisfies the topocentric trait (for which `istopocentriccrs(crs) == true`) must implement the following methods:
- `ecef_origin(crs::CRS)`: This function shall return the coordinate (in the linked ECEF CRS) of the origin of the provided `crs`.
- `lla_origin(crs::CRS)`: This function shall return the coordinate (in the linked LLA CRS) of the origin of the provided `crs`.

# Examples
```julia
enu_crs = ENU(LLA(0,0,1200km)) # ENU centered around a point at 1200km

enu_coord = enu_crs(0, 0, 100km) # A point 0m East, 0m North, 100km Up from the origin of the CRS

change_crs(LLA(), enu_coord) == LLA(0, 0, 1300km) # The same point expressed in LLA CRS
```

See also: [`istopocentriccrs`](@ref), [`ecef_origin`](@ref), [`lla_origin`](@ref), [`NED`](@ref)
""" ENU


#### AER ####
"""
    AER{CRS <: AbstractCRS, T}
Represents a position in the Azimuth-Elevation-Range (AER) coordinate system, which is a local coordinate system centered at a point on or above the surface of an Ellipsoid. 
The Elevation and Azimuth angles are always defined w.r.t. the ENU CRS with the same origin. More specifically:

!!! note
    This is actually a type alias for `SphericalCRS{ENU{CRS, T}, AzEl{ENU{CRS, T}}}`, but is provided for convenience.

# Properties/Units/Aliases
- `az` => u"°" => (azimuth,)
- `el` => u"°" => (elevation,)
- `r` => u"m" => (distance, range)

# Constructor
    AER(args...) = SphericalCRS(AzEl(ENU(args...)))

The constructor simply forwards all the arguments to the `ENU` constructor and then wraps the result in a `SphericalCRS` with the `AzEl` pointing CRS.

See also: [`ENU`](@ref), [`NED`](@ref), [`AzEl`](@ref), [`SphericalCRS`](@ref)
"""
const AER{CRS <: AbstractCRS, T} = SphericalCRS{ENU{CRS, T}, AzEl{ENU{CRS, T}}}
function AER(args...)
    enu_crs = ENU(args...)
    return SphericalCRS(AzEl(enu_crs))
end
# These are for solving ambiguities
AER(::Point{N, Number}) where N = _no_fastcoord_error(AER)
AER(::Vararg{Number}) = _no_fastcoord_error(AER)

PlutoShowHelpers.shortname(::AER) = "AER"
PlutoShowHelpers.repl_summary(aer::AER) = "AER{" * PlutoShowHelpers.shortname(getcrs(ecefcrs, aer)) * "}"

# Fast conversion between AER and NED
function transform_tuplecoords(crsₒ::AER{CRS}, crsᵢ::NED{CRS}, tup::NTuple{3, <:AbstractFloat}) where CRS <: AbstractCRS
    enu_crs = getcrs(cartesiancrs, crsₒ)
    enutup = transform_tuplecoords(enu_crs, crsᵢ, tup)
    return transform_tuplecoords(crsₒ, enu_crs, enutup)
end
function transform_tuplecoords(crsₒ::NED{CRS}, crsᵢ::AER{CRS}, tup::NTuple{3, <:AbstractFloat}) where CRS <: AbstractCRS
    enu_crs = getcrs(cartesiancrs, crsᵢ)
    enutup = transform_tuplecoords(enu_crs, crsᵢ, tup)
    return transform_tuplecoords(crsₒ, enu_crs, enutup)
end