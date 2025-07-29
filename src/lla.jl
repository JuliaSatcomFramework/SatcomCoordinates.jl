struct LLA{CRS <: AbstractCRS} <: AbstractCRS
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
    -π/2 ≤ lat ≤ π/2 || throw(ArgumentError("The input latitude must satisfy `-90° ≤ lat ≤ 90°`, while $(rad2deg(lat))° was provided"))
    return (lat, lon, alt)
end

#### Random.rand #####
function rand_tuplecoords(rng::AbstractRNG, ::LLA, T::Type{<:AbstractFloat})
    lat = rand(rng, T) * π - π/2
    lon = rand(rng, T) * 2π - π
    alt = zero(T)
    lat, lon, alt
end


##### Conversion with ECEF #####
struct ECEFtoLLA{ID} <: Transform
    id::ID
end
struct LLAtoECEF{ID} <: Transform
    id::ID
end

ellipsoidparams(t::Union{ECEFtoLLA, LLAtoECEF}) = ellipsoidparams(t.id)

TransformsBase.parameters(t::ECEFtoLLA) = (t.id,)
TransformsBase.isinvertible(::Union{Type{<:ECEFtoLLA}, Type{<:LLAtoECEF}}) = true
TransformsBase.isrevertible(::Union{Type{<:ECEFtoLLA}, Type{<:LLAtoECEF}}) = true

function TransformsBase.apply(t::ECEFtoLLA, tup::NTuple{3, <:AbstractFloat})
    ellparams = ellipsoidparams(t)
    ellipsoid = Ellipsoid(NamedTuple{(:a, :f, :b, :e², :el²)}(ellparams)...)
    lat, lon, alt = ecef_to_geodetic(SVector(tup); ellipsoid)
    return (lat, lon, alt), nothing
end

function TransformsBase.apply(t::LLAtoECEF, tup::NTuple{3, <:AbstractFloat})
    ellparams = ellipsoidparams(t)
    ellipsoid = Ellipsoid(NamedTuple{(:a, :f, :b, :e², :el²)}(ellparams)...)
    lat, lon, alt = tup
    x, y, z = geodetic_to_ecef(lat, lon, alt; ellipsoid)
    return (x, y, z), nothing
end

ncoords(::Type{<:Union{ECEFtoLLA, LLAtoECEF}}) = 3

TransformsBase.inverse(t::ECEFtoLLA) = LLAtoECEF(t.id)
TransformsBase.inverse(t::LLAtoECEF) = ECEFtoLLA(t.id)

### Transformation
function raw_linkedcrs_transform(crs::LLA)
    ecefcrs = linkedcrs(crs)
    raw = LLAtoECEF(ecefid(ecefcrs))
    return raw
end

# From ECEF to LLA
function transform_tuplecoords(::LLA{CRS}, crsᵢ::CRS, tup::NTuple{3, <:AbstractFloat}) where CRS <: AbstractCRS
    t = ECEFtoLLA(ecefid(crsᵢ))
    return t(tup)
end
# From LLA to ECEF
function transform_tuplecoords(::CRS, crsᵢ::LLA{CRS}, tup::NTuple{3, <:AbstractFloat}) where CRS <: AbstractCRS
    ecefcrs = linkedcrs(crsᵢ)
    t = LLAtoECEF(ecefid(ecefcrs))
    return t(tup)
end