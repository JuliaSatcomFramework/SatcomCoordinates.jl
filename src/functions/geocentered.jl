# Constructors

## ECI/ECEF
for P in (:ECI, :ECEF)
    # Constructor with specified numbertype
    eval(:(
    function $P{T}(xyz::Vararg{ValidDistance, 3}) where T <: AbstractFloat
        any(isnan, xyz) && return constructor_without_checks($P{T}, NaN * u"m", NaN * u"m", NaN * u"m")
        x, y, z = map(to_meters, xyz)
        constructor_without_checks($P{T}, x, y, z)
    end
    ))
    # Function without specified numbertype
    eval(:(
    function $P(xyz::Vararg{ValidDistance, 3})
        NT = promote_type(map(numbertype, xyz)...)
        T = NT <: AbstractFloat ? NT : Float64
        $P{T}(xyz...)
    end
    ))
end

## LLA
function LLA{T}(lat::ValidAngle, lon::ValidAngle, alt::ValidDistance) where T
    any(isnan, (lat, lon, alt)) && return constructor_without_checks(LLA{T}, NaN * u"°", NaN * u"°", NaN * u"m")
    lat = to_degrees(lat)
    lon = to_degrees(lon, RoundNearest)
    @assert -90° ≤ lat ≤ 90° "The input latitude must satisfy `lat ∈ [-90°, 90°]`"
    alt = to_meters(alt)
    constructor_without_checks(LLA{T}, lat, lon, alt)
end
function LLA(lat::ValidAngle, lon::ValidAngle, alt::ValidDistance)
    NT = promote_type(map(numbertype, (lat, lon, alt))...)
    T = NT <: AbstractFloat ? NT : Float64
    LLA{T}(lat, lon, alt)
end

# Isapprox
function Base.isapprox(x1::LLA, x2::LLA; angle_atol = deg2rad(1e-5), alt_atol = 1e-3, atol = nothing, kwargs...)
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

# Rand
function Random.rand(rng::AbstractRNG, ::Random.SamplerType{L}) where L <: LLA
    lat = rand(rng) * 180° - 90°
    lon = rand(rng) * 360° - 180°
    alt = 0.0 * u"m"
    constructor_without_checks(enforce_numbertype(L), lat, lon, alt)
end

function Random.rand(rng::AbstractRNG, ::Random.SamplerType{E}) where E <: Union{ECI, ECEF}
    C = enforce_numbertype(E)
    T = numbertype(C)
    p = rand(rng, PointingVersor{T}) |> to_svector
    x, y, z = p * (1e6 * ((1 + rand(rng)) * u"m"))
    constructor_without_checks(C, x, y, z)
end
