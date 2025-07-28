struct LLA{CRS <: AbstractCRS} <: AbstractCRS
    wrapped_crs::CRS
    function LLA(wrapped_crs::AbstractCRS) 
        CRS = typeof(wrapped_crs)
        apply_crs_predicate(CRS, isecefcrs) || throw(ArgumentError("The provided CRS ($CRS) is not an ECEF CRS, so it cannot be used to instantiate an LLA CRS"))
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

ellipsoidparams(crs::LLA) = ellipsoidparams(wrappedcrs(crs))

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
# From ECEF to LLA
function transform_tuplecoords(::LLA{CRS}, crsᵢ::CRS, tup::NTuple{3, <:AbstractFloat}) where CRS <: AbstractCRS
    ellparams = ellipsoidparams(crsᵢ)
    ellipsoid = Ellipsoid(NamedTuple{(:a, :f, :b, :e², :el²)}(ellparams)...)
    lat, lon, alt = ecef_to_geodetic(SVector(tup); ellipsoid)
    return (lat, lon, alt)
end
# From LLA to ECEF
function transform_tuplecoords(::CRS, crsᵢ::LLA{CRS}, tup::NTuple{3, <:AbstractFloat}) where CRS <: AbstractCRS
    ellparams = ellipsoidparams(crsᵢ)
    ellipsoid = Ellipsoid(NamedTuple{(:a, :f, :b, :e², :el²)}(ellparams)...)
    lat, lon, h = tup
    x, y, z = geodetic_to_ecef(lat, lon, h; ellipsoid)
    return (x, y, z)
end