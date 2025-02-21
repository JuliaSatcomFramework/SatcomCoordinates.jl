##### Constructors #####
function construct_inner_svector(PO::Type{PointingOffset{P, T}}, x, y) where {P <: Union{UV, AngularPointing}, T}
    _validate_type(PO)
    sv = SVector{2, T}(x, y)
    if P <: AngularPointing
        sv = map(ustrip ∘ to_degrees, sv)
    end
    return sv
end

_validate_type(::Type{<:PointingOffset{P}}) where P = P === basetype(P) || throw(ArgumentError("When defining `PointingOffset{P, T}` types, `P` can only be a subtype of `UV` or `AngularPointing` without its numbertype parameter expressed. You should define `P` as `$(basetype(P))` instead of the provided `$(P)`"))

_as_pointing(po::PointingOffset{P, T}) where {P, T} = constructor_without_checks(P{T}, raw_svector(po))
_from_pointing(uv::UV) = constructor_without_checks(PointingOffset{UV, numbertype(uv)}, raw_svector(uv))
_from_pointing(p::AngularPointing) = constructor_without_checks(PointingOffset{basetype(p), numbertype(p)}, raw_svector(p))

##### properties_names #####
properties_names(::Type{<:PointingOffset{P}}) where P = properties_names(P)

##### getproperties ####
ConstructionBase.getproperties(p::PointingOffset{<:AngularPointing}) = map(asdeg, raw_properties(p))

##### Basic Operations #####
function Base.:(-)(uv1::UV, uv2::UV) 
    T = promote_type(numbertype(uv1), numbertype(uv2))
    sv = SVector{2, T}(uv1.u - uv2.u, uv1.v - uv2.v)
    return constructor_without_checks(PointingOffset{UV, T}, sv)
end
Base.:(+)(uv::UV, δuv::UVOffset) = UV(uv.u + δuv.u, uv.v + δuv.v)

##### Random.rand #####
function Random.rand(rng::AbstractRNG, ::SamplerType{PO}) where {P, PO <: PointingOffset{P}}
    _validate_type(PO)
    POT = enforce_numbertype(PO)
    T = numbertype(POT)
    sv = rand(rng, P{T}) |> raw_svector
    return constructor_without_checks(POT, sv)
end

#### Utilities ####
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
	p₁_xyz = convert(PointingVersor, p₁) |> raw_svector
	p₂_xyz = convert(PointingVersor, p₂) |> raw_svector
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
	p₂_xyz = convert(PointingVersor, p₂) |> raw_svector # We create the 3D vector corresponding to p₂
	# Check the comments in `angle_offset_rotation` and the link therein to understand this line
    T = promote_type(numbertype(p₁), numbertype(p₂))
	sv = R' * p₂_xyz
    out = constructor_without_checks(PointingVersor{T}, sv)
	# We transform from local cartesian coordinates into ThetaPhi, and then we
	# convert into ThetaPhiOffset to emphasize that this is not a pointing
	# direction.
	tp = convert(ThetaPhi, out)
    return _from_pointing(tp)
end

"""
	p = add_angular_offset(p₀::AbstractPointing, offset_angles::Union{ThetaPhi, ThetaPhiOffset})
	p = add_angular_offset(p₀::PointingType, θ::ValidAngle, φ::ValidAngle = 0.0)
    p = add_angular_offset(output_type, p₀, args...)

Compute the resulting pointing direction `p` obtained by adding an angular offset
expressed as θ and φ angles (following the ISO/Physics convention for spherical
coordinates) [deg] to the starting position identified by `p₀`.

The input starting position `p₀` must be any subtype of `AbstractPointing`
The input `offset_angles` can be provided as an instance of one of the following types:
- `ThetaPhi`
- `ThetaPhiOffset`
and is converted to `ThetaPhiOffset` internally, with non-unitful values being interpreted as angles in degrees.

The output is of type `output_type` if provided or of the same type as `p₀` otherwise.

## Note
If `output_type` is `UV`, the function will throw an
error if the final pointing direction is located behind the viewer as the output in
UV would be ambiguous. This is not the case for other subtypes of `AbstractPointing` so an explicit output type (different from `UV`) should be provided if the target is expected to be behind the viewer.

The offset angles can also be provided separately as 2nd and 3rd argument
(optional, defaults to 0.0) to the function using the second method signature.
In this case, the inputs are treated as angles in degrees unless explicitly provided using quantitites with `°` unit from the Unitful package.

This function performs the inverse operation of [`get_angular_offset`](@ref) so
the following code should return true
```julia
using SatcomCoordinates
uv1 = UV(.3,.4)
uv2 = UV(-.2,.5)
offset = get_angular_offset(uv1, uv2)
p = add_angular_offset(uv1, offset)
p ≈ uv2
```

See also: [`get_angular_offset`](@ref), [`get_angular_distance`](@ref), [`ThetaPhi`](@ref), [`UV`](@ref)
"""
function add_angular_offset(::Type{O}, p₀::P, offset_angles::ThetaPhi) where {O <: AbstractPointing, P <: AbstractPointing}
	θφ_in = convert(ThetaPhi, p₀)
	R = angle_offset_rotation(θφ_in)
	perturbation = convert(PointingVersor, offset_angles) |> raw_svector
	# Check the comments in `angle_offset_rotation` and the link therein to understand this line
    T = promote_type(numbertype(p₀), numbertype(offset_angles))
	sv = R * perturbation
    out_direction = constructor_without_checks(PointingVersor{T}, sv)
    O <: UV && @assert out_direction.z >= 0 "The resulting point has a θ > 90°, so it is located behind the viewer.
Call the function with an explicit non-UV output type to allow target points behind the viewer."
    convert(O, out_direction)
end
add_angular_offset(O::Type{<:AbstractPointing}, p₀::AbstractPointing, θ::ValidAngle, φ::ValidAngle = 0.0) = add_angular_offset(O, p₀, ThetaPhi(θ, φ))
add_angular_offset(O::Type{<:AbstractPointing}, p₀::AbstractPointing, tpo::ThetaPhiOffset) = add_angular_offset(O, p₀, _as_pointing(tpo))
add_angular_offset(p₀::AbstractPointing, args...) = add_angular_offset(typeof(p₀), p₀, args...)

##### custom show overloads #####
PlutoShowHelpers.repl_summary(p::PointingOffset) = shortname(_as_pointing(p)) * " Pointing Offset"
PlutoShowHelpers.shortname(p::PointingOffset{P, T}) where {P, T} = shortname(P{T})*"Offset"

PlutoShowHelpers.show_namedtuple(p::PointingOffset) = show_namedtuple(_as_pointing(p))