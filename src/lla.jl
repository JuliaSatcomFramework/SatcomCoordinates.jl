struct LLA{CRS<:AbstractCRS} <: AbstractLinkedCRS{CRS}
    wrapped_crs::CRS
    function LLA(wrapped_crs::AbstractCRS)
        CRS = typeof(wrapped_crs)
        isecefcrs(basecrs(wrapped_crs)) || throw(ArgumentError("The provided CRS ($CRS) is not an ECEF CRS, so it cannot be used to instantiate an LLA CRS"))
        new{typeof(wrapped_crs)}(wrapped_crs)
    end
end
LLA() = LLA(ECEF())

@define_properties LLA [
    lat => u"°" => (:latitude,)
    lon => u"°" => (:longitude, :long)
    alt => u"m" => (:altitude, :h, :height)
]

default_wrappedcrs(::Type{<:LLA{<:Any}}) = ECEF()

ellipsoidparams(crs::LLA) = ellipsoidparams(linkedcrs(crs))

function process_unitless_coords(::Type{<:Coordinate}, crs::LLA, coords::NTuple{3,<:AbstractFloat})
    lat, lon, alt = coords
    lon = rem2pi(lon, RoundNearest)
    -π / 2 ≤ lat ≤ π / 2 || throw(ArgumentError("The input latitude must satisfy `-90° ≤ lat ≤ 90°`, while $(rad2deg(lat))° was provided"))
    return (lat, lon, alt)
end

#### Random.rand #####
function rand_tuplecoords(rng::AbstractRNG, ::LLA, T::Type{<:AbstractFloat})
    lat = rand(rng, T) * π - π / 2
    lon = rand(rng, T) * 2π - π
    alt = zero(T)
    lat, lon, alt
end


##### Conversion with ECEF #####

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

function TransformsBase.apply(t::ECEFtoLLA, tup::NTuple{3,<:AbstractFloat})
    ellparams = ellipsoidparams(t)
    ellipsoid = Ellipsoid(NamedTuple{(:a, :f, :b, :e², :el²)}(ellparams)...)
    lat, lon, alt = ecef_to_geodetic(SVector(tup); ellipsoid)
    return (lat, lon, alt), nothing
end

function TransformsBase.apply(t::LLAtoECEF, tup::NTuple{3,<:AbstractFloat})
    ellparams = ellipsoidparams(t)
    ellipsoid = Ellipsoid(NamedTuple{(:a, :f, :b, :e², :el²)}(ellparams)...)
    lat, lon, alt = tup
    x, y, z = geodetic_to_ecef(lat, lon, alt; ellipsoid)
    return (x, y, z), nothing
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

#### Custom isapprox implementation ####
function raw_isapprox(::Type{<:AbstractSatcomCoordinate}, crs1::LLA{CRS}, crs2::LLA{CRS}, coords1::NTuple{3,<:AbstractFloat}, coords2::NTuple{3,<:AbstractFloat}; angle_atol=1e-5u"°", alt_atol=1e-3u"m", atol=nothing, kwargs...) where CRS<:AbstractCRS
    x1 = NamedTuple{(:lat, :lon, :alt)}(coords1)
    x2 = NamedTuple{(:lat, :lon, :alt)}(coords2)
    alt_atol = enforce_unitless(u"m", alt_atol)
    angle_atol = remove_unit(u"°", u"rad", angle_atol)
    atol isa Optional{Nothing} || throw(ArgumentError("You can't provide an absolute tolerance directly for comparing `LLA` objects, please use the independent kwargs `angle_atol` [degrees] for the longitude and latitude atol and `alt_atol` [m] for the altitude one"))
    # Altitude, we default to an absolute tolerance of 1mm for isapprox
    isapprox(x1.alt, x2.alt; atol=alt_atol, kwargs...) || return false
    # Angles, we default to a default tolerance of 1e-5 degrees for isapprox
    ≈(x, y) = isapprox(x, y; atol=angle_atol, kwargs...)
    # Don't care about different longitude if latitude is ±90°
    abs(x1.lat) ≈ 90° && abs(x2.lat) ≈ 90° && return true
    # Return true if all the lat and lon are matching
    x1.lat ≈ x2.lat && (x1.lon ≈ x2.lon || abs(x1.lon) ≈ abs(x2.lon) ≈ π) && return true
    return false
end