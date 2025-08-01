"""
    LLA{CRS<:AbstractCRS} <: AbstractLinkedCRS{CRS}

A coordinate system that represents a point in latitude, longitude and altitude over a specific ellipsoid.
It is derived from an ECEF CRS and wraps it.

# Properties/Units/Aliases
- `lat` => u"°" => (latitude, lat, l): Latitude
- `lon` => u"°" => (longitude, lon, l): Longitude
- `alt` => u"m" => (altitude, alt, h, height): Altitude

# Constructor
    LLA(wrapped_crs::AbstractCRS)

The constructor expects a CRS as input, which must be an ECEF CRS.
"""
struct LLA{CRS<:AbstractCRS} <: AbstractLinkedCRS{CRS}
    wrapped_crs::CRS
    function LLA(wrapped_crs::AbstractCRS)
        CRS = typeof(wrapped_crs)
        isecefcrs(basecrs(wrapped_crs)) || throw(ArgumentError("The provided CRS ($CRS) is not an ECEF CRS, so it cannot be used to instantiate an LLA CRS"))
        new{typeof(wrapped_crs)}(wrapped_crs)
    end
end
LLA() = LLA(ECEF())
# Get 0 altitude if not provided
(crs::LLA)(lat::Number, lon::Number) = crs(lat, lon, 0)

isllacrs(::Type{<:LLA}) = true

@define_properties LLA [
    lat => u"°" => (:latitude,)
    lon => u"°" => (:longitude, :long)
    alt => u"m" => (:altitude, :h, :height)
]

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