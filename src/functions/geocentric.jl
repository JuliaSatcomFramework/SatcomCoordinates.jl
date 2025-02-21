##### Constructors #####

## ECI/ECEF
# Handled by generic LengthCartesian constructor in fallbacks.jl

## LLA
function construct_inner_svector(::Type{LLA{T}}, lat::ValidAngle, lon::ValidAngle, alt::ValidDistance) where T <: AbstractFloat
    lat = to_degrees(lat) |> stripdeg
    lon = to_degrees(lon, RoundNearest) |> stripdeg
    @assert -90° ≤ lat ≤ 90° "The input latitude must satisfy `lat ∈ [-90°, 90°]`"
    alt = to_meters(alt) |> ustrip
    return SVector{3, T}(lat, lon, alt)
end
# Constructor without altitude
(L::Type{<:LLA})(lat::ValidAngle, lon::ValidAngle) = L(lat, lon, 0)

##### Base.getproperty #####
# LLA
properties_names(::Type{<:LLA}) = (:lat, :lon, :alt)

##### Base.isapprox #####
function Base.isapprox(x1::LLA, x2::LLA; angle_atol = 1e-5°, alt_atol = 1e-3, atol = nothing, kwargs...)
    alt_atol = to_meters(alt_atol) |> ustrip
    angle_atol = to_degrees(angle_atol) |> stripdeg
	@assert atol isa Nothing "You can't provide an absolute tolerance directly for comparing `LLA` objects, please use the independent kwargs `angle_atol` [radians] for the longitude and latitude atol and `alt_atol` [m] for the altitude one"
    x1 = raw_properties(x1)
    x2 = raw_properties(x2)
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
    LT = enforce_numbertype(L)
    T = numbertype(LT)
    lat = rand(rng) * π - π/2
    lon = rand(rng) * 2π - π
    alt = 0.0
    constructor_without_checks(LT, SVector{3, T}(lat, lon, alt))
end

function Random.rand(rng::AbstractRNG, ::Random.SamplerType{E}) where E <: Union{ECI, ECEF}
    C = enforce_numbertype(E)
    T = numbertype(C)
    p = rand(rng, PointingVersor{T}) |> raw_svector
    sv = p * (7e6 * ((1 + rand(rng))))
    constructor_without_checks(C, sv)
end
