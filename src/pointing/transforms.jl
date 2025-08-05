##### Conversions #####
"""
    abstract type PointingTransform <: AbstractRawCRSTransform end

Abstract type for all transformations that used to convert between a 2D pointing CRS to the DirectionCosines one (and vice-versa).

These are **raw** transforms and are also used to go to map to the 
"""
abstract type PointingTransform <: AbstractRawCRSTransform end

struct AngularPointingToDirectionCosines{PT <: Abstract2DPointingCRS} <: PointingTransform end
struct DirectionCosinesToAngularPointing{PT <: Abstract2DPointingCRS} <: PointingTransform end

ncoords_in(::Type{<:AngularPointingToDirectionCosines{PT}}) where PT = return 2
ncoords_out(::Type{<:AngularPointingToDirectionCosines{PT}}) where PT = return 3
ncoords_in(::Type{<:DirectionCosinesToAngularPointing{PT}}) where PT = return 3
ncoords_out(::Type{<:DirectionCosinesToAngularPointing{PT}}) where PT = return 2

TransformsBase.isinvertible(::Type{<:PointingTransform}) = return true
TransformsBase.isrevertible(::Type{<:PointingTransform}) = return true

TransformsBase.inverse(::AngularPointingToDirectionCosines{PT}) where PT = return DirectionCosinesToAngularPointing{PT}()
TransformsBase.inverse(::DirectionCosinesToAngularPointing{PT}) where PT = return AngularPointingToDirectionCosines{PT}()

function raw_linkedcrs_transform(::AbstractPointingCRS)
    throw(ArgumentError("It is not possible to go from a Pointing CRS to its linked Cartesian CRS as the information about the distance from the origin is lost"))
end

# Generic implementation for the transform_tuplecoords

# UV <-> DirectionCosines
function TransformsBase.apply(::AngularPointingToDirectionCosines{<:UV}, tup::NTuple{2, <:AbstractFloat})
    u, v = tup
    w = sqrt(1 - u^2 - v^2)
    return (u, v, w), nothing
end
function TransformsBase.apply(::DirectionCosinesToAngularPointing{<:UV}, tup::NTuple{3, T}) where T <: AbstractFloat
    u, v, w = tup
    isnan(w) && return map(T, (NaN, NaN)), nothing
    w >= 0 || throw(ArgumentError("The provided values in the `DirectionCosines` CRS are not valid as they are located in the half-hemisphere containing the cartesian -Z axis and can not be converted to UV coordinates"))
    return (u, v), nothing
end

# ThetaPhi <-> UV (Specific implementation for slightly faster conversion)
function transform_tuplecoords(::UV{CRS}, ::ThetaPhi{CRS}, tup::NTuple{2, T}) where {CRS <: AbstractCRS, T <: AbstractFloat}
    any(isnan, tup) && return map(T, (NaN, NaN))
    θ, φ = tup
	θ <= π/2 || throw(ArgumentError("The provided ThetaPhi coordinate has θ > 90° so it lies in the half-hemisphere containing the -Z axis and can not be represented in UV"))
	v, u = sin(θ) .* sincos(φ)
    return (u, v)
end
function transform_tuplecoords(::ThetaPhi{CRS}, ::UV{CRS}, tup::NTuple{2, <:AbstractFloat}) where CRS <: AbstractCRS
    u, v = tup
    θ = asin(sqrt(u^2 + v^2))
    φ = atan(v,u)
    return (θ, φ)
end

# ThetaPhi <-> DirectionCosines
function TransformsBase.apply(::AngularPointingToDirectionCosines{<:ThetaPhi}, tup::NTuple{2, <:AbstractFloat})
    θ, φ = tup
	sθ,cθ = sincos(θ)
	sφ,cφ = sincos(φ)
	u = sθ * cφ
	v = sθ * sφ 
	w = cθ
    return (u, v, w), nothing
end
function TransformsBase.apply(::DirectionCosinesToAngularPointing{<:ThetaPhi}, tup::NTuple{3, <:AbstractFloat})
    (u, v, w) = tup
	θ = acos(w)
	φ = atan(v,u)
    return (θ, φ), nothing
end

# ThetaPhi <-> AzEl
# We can have a much simpler direct conversion between the two without passing by the PointingVersor
function transform_tuplecoords(::AzEl{CRS}, ::ThetaPhi{CRS}, tup::NTuple{2, <:AbstractFloat}) where CRS <: AbstractCRS
    θ, φ = tup
    az = rem2pi(π/2 - φ, RoundNearest)
    el = π/2 - θ # Already in the [-90°, 90°] range
    (az, el)
end
function transform_tuplecoords(::ThetaPhi{CRS}, ::AzEl{CRS}, tup::NTuple{2, <:AbstractFloat}) where CRS <: AbstractCRS
    az, el = tup
    θ = π/2 - el
    φ = rem2pi(π/2 - az, RoundNearest)
    (θ, φ)
end

# AzEl <-> DirectionCosines
#= Conversion from https://gssc.esa.int/navipedia/index.php/Transformations_between_ECEF_and_ENU_coordinates knowing that:
- p̂ ⋅ ê = u
- p̂ ⋅ n̂ = v
- p̂ ⋅ û = w
=#
function TransformsBase.apply(::DirectionCosinesToAngularPointing{<:AzEl}, tup::NTuple{3, <:AbstractFloat})
    u,v,w = tup
    az = atan(u, v) # Already in the [-180°, 180°] range
    el = asin(w) # Already in the [-90°, 90°] range
    return (az, el), nothing
end
function TransformsBase.apply(::AngularPointingToDirectionCosines{<:AzEl}, tup::NTuple{2, <:AbstractFloat})
    az, el = tup
    saz,caz = sincos(az)
    sel,cel = sincos(el)
    u = saz * cel
    v = caz * cel
    w = sel
    return (u, v, w), nothing
end

# ElOverAz <-> DirectionCosines
function TransformsBase.apply(::DirectionCosinesToAngularPointing{<:ElOverAz}, tup::NTuple{3, <:AbstractFloat})
    u,v,w = tup
    az = atan(-u,w) # Already in the [-180°, 180°] range
    el = asin(v) # Already in the [-90°, 90°] range
    return (az, el), nothing
end
function TransformsBase.apply(::AngularPointingToDirectionCosines{<:ElOverAz}, tup::NTuple{2, <:AbstractFloat})
    az, el = tup
    saz,caz = sincos(az)
    sel,cel = sincos(el)
    u = -saz * cel
    v = sel
    w = caz * cel
    return (u, v, w), nothing
end

# AzOverEl <-> DirectionCosines
function TransformsBase.apply(::DirectionCosinesToAngularPointing{<:AzOverEl}, tup::NTuple{3, <:AbstractFloat})
    u, v, w = tup
    el = atan(v/w) # Already returns a value in the range [-90°, 90°]
    az = asin(-u) # This only returns the value in the [-90°, 90°] range
    # Make the angle compatible with our ranges of azimuth and elevation
    az = ifelse(w >= 0, az, copysign(180°, az) - az)
    return (az, el), nothing
end
function TransformsBase.apply(::AngularPointingToDirectionCosines{<:AzOverEl}, tup::NTuple{2, <:AbstractFloat})
    az, el = tup
    sel,cel = sincos(el)
    saz,caz = sincos(az)
    u = -saz
    v = caz * sel
    w = caz * cel
    return (u, v, w), nothing
end

# Conversion fallbacks
# Conversion between non DirectionCosines pointing types, passing through DirectionCosines
function transform_tuplecoords(::DirectionCosines{CRS}, ::PT, tup::NTuple{2, <:AbstractFloat}) where {CRS <: AbstractCRS, PT <: Abstract2DPointingCRS{CRS}}
    pt2dc = AngularPointingToDirectionCosines{PT}()
    pt2dc(tup)
end
function transform_tuplecoords(::PT, ::DirectionCosines{CRS}, tup::NTuple{3, <:AbstractFloat}) where {CRS <: AbstractCRS, PT <: Abstract2DPointingCRS{CRS}}
    dc2pt = DirectionCosinesToAngularPointing{PT}()
    dc2pt(tup)
end
function transform_tuplecoords(crsₒ::AbstractPointingCRS{CRS}, crsᵢ::AbstractPointingCRS{CRS}, tup::NTuple{2, <:AbstractFloat}) where CRS <: AbstractCRS
    dc = DirectionCosines(getcrs(linkedcrs, crsₒ))
    uvw = transform_tuplecoords(dc, crsᵢ, tup)
    return transform_tuplecoords(crsₒ, dc, uvw)
end

# This are to handle the case of going from CRS to AbstractPointingCRS{CRS}. The other direction is explicitly not supported
function transform_tuplecoords(crsₒ::DirectionCosines{CRS}, crsᵢ::CRS, tup::NTuple{3, <:AbstractFloat}) where CRS <: AbstractCRS
    is_same_crs(getcrs(linkedcrs, crsₒ), crsᵢ) || _missing_conversion_method(crsₒ, crsᵢ)
    return _normalize(tup)
end
function transform_tuplecoords(crsₒ::AbstractPointingCRS{CRS}, crsᵢ::CRS, tup::NTuple{3, <:AbstractFloat}) where CRS <: AbstractCRS
    dc = DirectionCosines(crsᵢ)
    dctup = transform_tuplecoords(dc, crsᵢ, tup)
    return transform_tuplecoords(crsₒ, dc, dctup)
end