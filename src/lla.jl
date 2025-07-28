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