# Pointing Versor
function PointingVersor{T}(x, y,z) where T <: AbstractFloat
    v = normalize(SVector{3, T}(x, y, z))
    return constructor_without_checks(PointingVersor{T}, v...)
end

to_svector(p::PointingVersor) = SVector{3, numbertype(p)}(p.x, p.y, p.z)

Base.isapprox(p1::PointingVersor, p2::PointingVersor; kwargs...) = isapprox(to_svector(p1), to_svector(p2); kwargs...)

function Base.getproperty(p::PointingVersor, s::Symbol)
    s ∈ (:x, :u) && return getfield(p, :x)
    s ∈ (:y, :v) && return getfield(p, :y)
    s ∈ (:z, :w) && return getfield(p, :z)
end

(::Type{P})(pt::Point{3, Real}) where P <: PointingVersor = P(pt...)

# UV
const UV_CONSTRUCTOR_TOLERANCE = Ref{Float64}(1e-5)

function UV{T}(u, v) where {T <: AbstractFloat}
    (isnan(u) || isnan(v)) && return constructor_without_checks(UV{T}, NaN, NaN)
    n = u^2 + v^2
    tol = UV_CONSTRUCTOR_TOLERANCE[]
    lim = 1 + tol
    if (n > 1 && n <= lim)
        c = 1 / sqrt(n)
        u *= c
        v *= c
    end
    if (n > lim) 
        error("The provided inputs do not satisfy u^2 + v^2 <= 1 + tolerance
u = $u 
v = $v 
u^2 + v^2 = $n
tolerance = $(tol)")
    end
    constructor_without_checks(UV{T}, u, v)
end

(::Type{P})(pt::Point{2, Real}) where P <: UV = P(pt...)


## Conversions UV <-> PointingVersor
_convert_different(::Type{P}, uv::UV) where {P <: PointingVersor} = constructor_without_checks(enforce_numbertype(P, uv), uv.u, uv.v, sqrt(1 - uv.u^2 - uv.v^2))
function _convert_different(::Type{U}, pv::PointingVersor) where U <: UV 
    @assert pv.z >= 0 "The provided PointingVersor is located in the half-hemisphere containing the cartesian -Z axis and can not be converted to UV coordinates"
    constructor_without_checks(enforce_numbertype(U, pv), pv.x, pv.y)
end
## Conversion UV <-> ThetaPhi
# Specific implementation for slightly faster conversion
function _convert_different(::Type{U}, tp::ThetaPhi) where U <: UV
	(;θ,φ) = tp
	@assert θ <= 90° "The provided ThetaPhi pointing $tp has θ > 90° so it lies in the half-hemisphere containing the -Z axis and can not be represented in UV"
	v, u = sin(θ) .* sincos(φ)
	return constructor_without_checks(enforce_numbertype(U, tp), u, v)
end
function _convert_different(::Type{TP}, uv::UV) where TP <: ThetaPhi
	(;u,v) = uv
	θ = asin(sqrt(u^2 + v^2)) |> asdeg
	φ = atan(v,u) |> asdeg
	return constructor_without_checks(enforce_numbertype(TP, uv), θ, φ)
end

### ThetaPhi ###
# getproperty
function Base.getproperty(p::ThetaPhi, s::Symbol)
    s ∈ (:t, :θ, :theta) && return getfield(p, :θ)
    s ∈ (:p, :φ, :ϕ, :phi) && return getfield(p, :φ)
end

## Conversions ThetaPhi <-> PointingVersor
function _convert_different(::Type{P}, tp::ThetaPhi) where P <: PointingVersor
	(; θ, φ) = raw_nt(tp)
	sθ,cθ = sincos(θ)
	sφ,cφ = sincos(φ)
	x = sθ * cφ
	y = sθ * sφ 
	z = cθ
    constructor_without_checks(enforce_numbertype(P, tp), x, y, z)
end
function _convert_different(::Type{TP}, pv::PointingVersor) where TP <: ThetaPhi
	(;x,y,z) = pv
	θ = acos(z) |> asdeg
	φ = atan(y,x) |> asdeg
    constructor_without_checks(enforce_numbertype(TP, pv), θ, φ)
end


### AzOverEl/ElOverAz ###


function (::Type{P})(α, β) where{T <: AbstractFloat, P <: Union{AzOverEl{T}, ElOverAz{T}, ThetaPhi{T}}}
    (isnan(α) || isnan(β)) && return constructor_without_checks(P, f(NaN), f(NaN))
    α = to_degrees(α, RoundNearest)
    β = to_degrees(β, RoundNearest)
    α, β = wrap_spherical_angles_normalized(α, β, P)
    constructor_without_checks(P, α, β)
end

# getproperty
function Base.getproperty(p::Union{AzOverEl, ElOverAz}, s::Symbol)
    s ∈ (:az, :azimuth) && return getfield(p, :az)
    s ∈ (:el, :elevation) && return getfield(p, :el)
end

## Conversions ElOverAz <-> PointingVersor
function _convert_different(::Type{E}, p::PointingVersor) where E <: ElOverAz
    (;u,v,w) = p
    az = atan(-u,w) |> asdeg # Already in the [-180°, 180°] range
    el = asin(v) |> asdeg # Already in the [-90°, 90°] range
    constructor_without_checks(enforce_numbertype(E, p), az, el)
end
function _convert_different(::Type{P}, p::ElOverAz) where P <: PointingVersor
    (;az, el) = raw_nt(p)
    saz,caz = sincos(az)
    sel,cel = sincos(el)
    x = -saz * cel
    y = sel
    z = caz * cel
    constructor_without_checks(enforce_numbertype(P, p), x, y, z)
end


## Conversions AzOverEl <-> PointingVersor
function _convert_different(::Type{A}, p::PointingVersor) where A <: AzOverEl
    (;u,v,w) = p
    el = atan(v/w) |> asdeg # Already returns a value in the range [-90°, 90°]
    az = asin(-u) |> asdeg # This only returns the value in the [-90°, 90°] range
    # Make the angle compatible with our ranges of azimuth and elevation
    az = ifelse(w >= 0, az, copysign(180°, az) - az)
    constructor_without_checks(enforce_numbertype(A, p), az, el)
end
function _convert_different(::Type{P}, p::AzOverEl) where P <: PointingVersor
    (;el, az) = raw_nt(p)
    sel,cel = sincos(el)
    saz,caz = sincos(az)
    x = -saz
    y = caz * sel
    z = caz * cel
    constructor_without_checks(enforce_numbertype(P, p), x, y, z)
end

### Fallbacks
# Constructors without numbertype, and with tuple or SVector as input
for P in (:UV, :ThetaPhi, :AzOverEl, :ElOverAz, :PointingVersor)
    NT = P in (:UV, :PointingVersor) ? :Real : :ValidAngle
    N = P === :PointingVersor ? 3 : 2
    eval(:(
    function $P(vals::Vararg{$NT, $N})
        T = promote_type(map(numbertype, vals)...)
        T = T <: AbstractFloat ? T : Float64
        $P{T}(vals...)
    end
    ))
end

# Angular pointing version with Tuple/SVector as input
(::Type{P})(pt::Point2D) where P <: AngularPointing = P(pt...)

# Conversion between non PointingVersor pointing types, passing through PointingVersor
function _convert_different(::Type{D}, p::S) where {D <: AbstractPointing, S <: AbstractPointing}
    pv = convert(PointingVersor, p)
    return convert(D, pv)
end

# General isapprox method
Base.isapprox(p1::PointingVersor, p2::Union{UV, AngularPointing}; kwargs...) = isapprox(p1, convert(PointingVersor, p2); kwargs...)
Base.isapprox(p1::Union{UV, AngularPointing}, p2::PointingVersor; kwargs...) = isapprox(p2, p1; kwargs...)
Base.isapprox(p1::Union{UV, AngularPointing}, p2::Union{UV, AngularPointing}; kwargs...) = isapprox(convert(PointingVersor, p1), p2; kwargs...)

# Rand methods
Random.rand(rng::AbstractRNG, ::Random.SamplerType{P}) where P <: PointingVersor =
    P((rand(rng) - .5 for _ in 1:3)...)

function Random.rand(rng::AbstractRNG, ::Random.SamplerType{U}) where U <: UV
    p = PointingVersor(rand(rng) - .5, rand(rng) - .5, rand(rng))
    constructor_without_checks(enforce_numbertype(U), p.x, p.y)
end

function Random.rand(rng::AbstractRNG, ::Random.SamplerType{TP}) where TP <: ThetaPhi
    θ = rand(rng) * 180°
    φ = rand(rng) * 360° - 180°
    constructor_without_checks(enforce_numbertype(TP), θ, φ)
end

function Random.rand(rng::AbstractRNG, ::Random.SamplerType{AE}) where AE <: Union{AzOverEl, ElOverAz}
    az = rand(rng) * 360° - 180°
    el = rand(rng) * 180° - 90°
    constructor_without_checks(enforce_numbertype(AE), az, el)
end

# Utilities
LinearAlgebra.dot(p1::PointingVersor, p2::PointingVersor) = p1.x * p2.x + p1.y * p2.y + p1.z * p2.z

"""
	get_angular_distance(p₁::AbstractPointing, p₂::AbstractPointing)

Compute the angular distance [°] between the target pointing direction `p₂` and the
starting pointing direction `p₁`. 

## Note

This function's output should be approximately equivalent to the θ (theta) component of
[`get_angular_offset`](@ref) but has a faster implementation. 
Use this in case the φ (phi) component is not required and speed is important.  The following code should evaluate to true
```julia
using SatcomCoordinates
uv1 = UV(.3,.4)
uv2 = UV(-.2,.5)
offset = get_angular_offset(uv1, uv2)
Δθ = get_angular_distance(uv1, uv2)
offset.theta ≈ Δθ
```

See also: [`add_angular_offset`](@ref), [`get_angular_offset`](@ref)
"""
function get_angular_distance(p₁::AbstractPointing, p₂::AbstractPointing)
	p₁_xyz = convert(PointingVersor, p₁) |> to_svector
	p₂_xyz = convert(PointingVersor, p₂) |> to_svector
	return acos(min(p₁_xyz'p₂_xyz, 1)) |> asdeg
end

"""
	angle_offset_rotation(θ, φ)

Compute the rotation matrix to find offset points following the procedure in
this stackexchnge answer:
https://math.stackexchange.com/questions/4343044/rotate-vector-by-a-random-little-amount
"""
function angle_offset_rotation(θ::Deg, φ::Deg)
	# Precompute the sines and cosines
    θ, φ = promote(θ, φ)
	sθ, cθ = sincos(θ |> stripdeg)
	sφ, cφ = sincos(φ |> stripdeg)
    T = typeof(sθ)
	
	# Compute the versors of the spherical to cartesian transformation as per
	# [Wikipedia](https://en.wikipedia.org/wiki/Spherical_coordinate_system#Integration_and_differentiation_in_spherical_coordinates)
	r̂ = SVector{3, T}(sθ*cφ, sθ*sφ, cθ)
	θ̂ = SVector{3, T}(cθ*cφ, cθ*sφ, -sθ)
	φ̂ = SVector{3, T}(-sφ, cφ, zero(T))

	# The standard basis for spherical coordinates is r̂, θ̂, φ̂. We instead
	# want a basis that has r̂ as third vector (e.g. ẑ in normal cartesian
	# coordinates), and we want to rotate the other two vectors in a way that
	# the second vector is pointing towards Positive ŷ (i.e. similar to how ENU
	# has the second direction pointing towards North). 
	# To achieve this, we have to reorder the versor and then perform a matrix
	# rotation around the new third axis (which is r̂) by an angle that depends
	# on φ.
	# See
	# ![image](https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Kugelkoord-lokale-Basis-s.svg/360px-Kugelkoord-lokale-Basis-s.svg.png)
	# for a reference figure of the original spherical versors.
	_R = hcat(-φ̂, θ̂, r̂) # φ̂ has to change sign to maintain the right-rule axis order
	# We have to create a rotation matrix around Z that is equivalent to π/2 - φ

	# We use the RotZ Matrix definition in
	# https://en.wikipedia.org/wiki/Rotation_matrix#Basic_rotations, but
	# remembering that: 
	# cos(π/2 - φ) = sin(φ)
	# sin(π/2 - φ) = cos(φ)
	__R = SA{T}[
		sφ -cφ 0
		cφ sφ 0
		0 0 1
	]

	return _R*__R
end
angle_offset_rotation(tp::ThetaPhi) = angle_offset_rotation(tp.θ, tp.φ)

"""
	offset = get_angular_offset(p₁::AbstractPointing, p₂::AbstractPointing)::ThetaPhiOffset
Compute the angular offset required to reach the target pointing direction `p₂`
from starting pointing direction `p₁`. 
The two input pointings can be of any valid `AbstractPointing` type.

The output is of type `ThetaPhiOffset`

# Note
This function performs the inverse operation of [`add_angular_offset`](@ref) so
the following code should return true

```julia
using ReferenceViews
uv1 = UV(.3,.4)
uv2 = UV(-.2,.5)
offset = get_angular_offset(uv1, uv2)
p = add_angular_offset(uv1, offset)
p ≈ uv2
```

Check out [`get_angular_distance`](@ref) for a slightly faster implementation in
case you only require the angular distance rather than the 2D offset.

See also: [`add_angular_offset`](@ref)
"""
function get_angular_offset(p₁::AbstractPointing, p₂::AbstractPointing)
	R = angle_offset_rotation(convert(ThetaPhi, p₁)) # We take p₁ as reference
	p₂_xyz = convert(PointingVersor, p₂) |> to_svector # We create the 3D vector corresponding to p₂
	# Check the comments in `angle_offset_rotation` and the link therein to understand this line
	x, y, z = R' * p₂_xyz
    out = constructor_without_checks(enforce_numbertype(PointingVersor, x), x, y, z)
	# We transform from local cartesian coordinates into ThetaPhi, and then we
	# convert into ThetaPhiOffset to emphasize that this is not a pointing
	# direction.
	return convert(ThetaPhi, out)
end

# This function will return the cartesian coordinate of the new pointing direction (unitary norm) after the rotation by the offset angle
function add_angular_offset(p₀::P, offset_angles::ThetaPhi) where P <: AbstractPointing
	θφ_in = convert(ThetaPhi, p₀)
	R = angle_offset_rotation(θφ_in)
	perturbation = convert(PointingVersor, offset_angles) |> to_svector
	# Check the comments in `angle_offset_rotation` and the link therein to understand this line
	x,y,z = R * perturbation
    out_direction = constructor_without_checks(enforce_numbertype(PointingVersor, x), x, y, z)
    P <: UV && @assert out_direction.z >= 0 "The resulting point has a θ > 90°, so it is located behind the viewer.
Convert the starting point to ThetaPhi before calling this function to allow target points behind the viewer."
    convert(P, out_direction)
end