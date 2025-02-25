##### Constructors #####

## ECI/ECEF
# Handled by generic LengthCartesian constructor in fallbacks.jl

## LLA
function LLA{T}(lat::ValidAngle, lon::ValidAngle, alt::ValidDistance) where T
    any(isnan, (lat, lon, alt)) && return LLA{T}(Val{NaN}())
    lat = to_degrees(lat)
    lon = to_degrees(lon, RoundNearest)
    @assert -90° ≤ lat ≤ 90° "The input latitude must satisfy `lat ∈ [-90°, 90°]`"
    alt = to_meters(alt)
    constructor_without_checks(LLA{T}, lat, lon, alt)
end
function LLA(lat::ValidAngle, lon::ValidAngle, alt::ValidDistance)
    T = default_numbertype(lat, lon, alt)
    LLA{T}(lat, lon, alt)
end
(::Type{L})(lat::ValidAngle, lon::ValidAngle) where L <: LLA = L(lat, lon, 0)

##### Base.getproperty #####
# LLA
property_aliases(::Type{<:LLA}) = (
    lat = LATITUDE_ALIASES,
    lon = LONGITUDE_ALIASES,
    alt = ALTITUDE_ALIASES
)

##### Base.isapprox #####
function Base.isapprox(x1::LLA, x2::LLA; angle_atol = deg2rad(1e-5), alt_atol = 1e-3, atol = nothing, kwargs...)
    alt_atol = to_meters(alt_atol)
	@assert atol isa Nothing "You can't provide an absolute tolerance directly for comparing `LLA` objects, please use the independent kwargs `angle_atol` [radians] for the longitude and latitude atol and `alt_atol` [m] for the altitude one"
	# Altitude, we default to an absolute tolerance of 1mm for isapprox
	isapprox(x1.alt,x2.alt; atol = alt_atol, kwargs...) || return false
	# Angles, we default to a default tolerance of 1e-5 degrees for isapprox
	≈(x,y) = isapprox(x,y;atol = angle_atol, kwargs...)
	# Don't care about different longitude if latitude is ±90°
	abs(x1.lat) ≈ 90° && abs(x2.lat) ≈ 90° && return true
	# Return true if all the lat and lon are matching
	x1.lat ≈ x2.lat && (x1.lon ≈ x2.lon || abs(x1.lon) ≈ abs(x2.lon) ≈ π) && return true
	return false
end

##### Random.rand #####
function Random.rand(rng::AbstractRNG, ::Random.SamplerType{L}) where L <: LLA
    lat = rand(rng) * 180° - 90°
    lon = rand(rng) * 360° - 180°
    alt = 0.0 * u"m"
    constructor_without_checks(enforce_numbertype(L), lat, lon, alt)
end

function Random.rand(rng::AbstractRNG, ::Random.SamplerType{E}) where E <: Union{ECI, ECEF}
    C = enforce_numbertype(E)
    T = numbertype(C)
    p = rand(rng, PointingVersor{T}) |> normalized_svector
    x, y, z = p * (7e6 * ((1 + rand(rng)) * u"m"))
    constructor_without_checks(C, x, y, z)
end
