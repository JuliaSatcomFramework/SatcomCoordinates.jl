"""
    PointingVersor{T} <: AbstractPointing{T, 3}

A unit vector (versor) representing a pointing direction in 3D space. Its components
are the `x`, `y`, and `z` components of the unit vector and can also be seen as
the `u`, `v`, and `w` direction cosines of the direction identified by the
`PointingVersor` instance.

# Fields
- `x::T`: The component along the X axis of the corresponding reference frame. Can also be accessed with the `u` property name.
- `y::T`: The component along the Y axis of the corresponding reference frame. Can also be accessed with the `v` property name.
- `z::T`: The component along the Z axis of the corresponding reference frame. Can also be accessed with the `w` property name.

See also: [`UV`](@ref), [`ThetaPhi`](@ref), [`AzOverEl`](@ref), [`ElOverAz`](@ref)
"""
struct PointingVersor{T} <: AbstractPointing{T, 3}
    x::T
    y::T
    z::T

    BasicTypes.constructor_without_checks(::Type{PointingVersor{T}}, x, y, z) where T = new{T}(x, y, z)
end

# UV
"""
    UV{T} <: AbstractPointing{T, 2}

Specify a pointing direction in UV coordinates, which are equivalent to the direction cosines with respect to the `X` and `Y` axis of the reference frame. They can also be related to the spherical coordinates (ISO/Physics) [spherical coordinates
representation](https://en.wikipedia.org/wiki/Spherical_coordinate_system) by the following equations:
- `u = sin(θ) * cos(φ)`
- `v = sin(θ) * sin(φ)`

!!! note
    UV coordinates can only be used to represent pointing direction in the
    half-hemisphere containing the cartesian +Z axis.

!!! note
    The inputs values must also satisfy `u^2 + v^2 <= 1 + SatcomCoordinates.UV_CONSTRUCTOR_TOLERANCE[]` or an error will be thrown. The `SatcomCoordinates.UV_CONSTRUCTOR_TOLERANCE` is a `Ref{Float64}` which defaults to 1e-5 (In case `u^2 + v^2 > 1` the inputs are normalized to ensure `u^2 + v^2 = 1`).

# Fields
- `u::T`
- `v::T`

# Basic Constructors
	UV{T}(u,v)
The basic constructor takes 2 separate numbers `u`, `v` and instantiate the object assuming that `u^2 + v^2 <=
1` (condition for valid UV pointing), throwing an error otherwise.\\
If either of the inputs is `NaN`, the returned `UV` object will contain `NaN` for both fields.


	UV{T}(uv)
The `UV{T}` can be created using any 2-element Tuple or StaticVector as input,
which will internally call the 2-arguments constructor.

See also: [`PointingVersor`](@ref), [`ThetaPhi`](@ref)
"""
struct UV{T} <: AbstractPointing{T, 2}
    u::T
    v::T
    BasicTypes.constructor_without_checks(::Type{UV{T}}, u, v) where {T} = new{T}(u, v)
end

# ThetaPhi
"""
    ThetaPhi{T} <: AngularPointing{T}

An object specifying a pointing direction in ThetaPhi coordinates, defined as the θ and φ in
the (ISO/Physics definition) [spherical coordinates
representation](https://en.wikipedia.org/wiki/Spherical_coordinate_system) 

Assuming `u`, `v`, and `w` to be direction cosines of the pointing versor `̂p`, their relation with the `θ` and `φ` angles is:
- `u = sin(θ) * cos(φ)`
- `v = sin(θ) * sin(φ)`
- `w = cos(θ)`

# Fields
- `θ::Deg{T}`: The so-called `polar angle`, representing the angle between the `Z` axis and the `XY` plane of the reference frame. It is always normalized to fall within the [-90°, 90°] range.
- `φ::Deg{T}`: The so-called `azimuth angle`, representing the angle between the `y` and `x` component of the pointing direction. It is always normalized to fall within the [-180°, 180°] range.

While the field name use the greek letters, the specific fields of an arbitrary
`ThetaPhi` object `tp` can be accessed with alternative symbols:
- `tp.θ`, `tp.theta` and `tp.t` can be used to access the `θ` field
- `tp.φ`, `tp.ϕ`, `tp.phi` and `tp.p` can be used to access the `φ` field

# Basic Constructors
	ThetaPhi(θ,φ)
The basic constructor takes 2 separate numbers `θ`, `φ` and instantiate the
object.\\
**Provided inputs are intepreted as degrees if not provided using angular quantities from Unitful.**
If either of the inputs is `NaN`, the returned `ThetaPhi` object will contain `NaN` for both fields.

	ThetaPhi(tp)
The `ThetaPhi` struct can be created using any 2-element Tuple or
Vector/StaticVector as input, which will internally call the 2-arguments
constructor.

See also: [`PointingVersor`](@ref), [`UV`](@ref)
"""
struct ThetaPhi{T} <: AngularPointing{T}
	θ::Deg{T}
	φ::Deg{T}
    BasicTypes.constructor_without_checks(::Type{ThetaPhi{T}}, θ::Deg, φ::Deg) where T = new{T}(θ, φ)
end

### AzOverEl ###
"""
    AzOverEl{T} <: AngularPointing{T}

Object specifying a pointing direction in "Azimuth over Elevation" coordinates, which specify the elevation and azimuth angles that needs to be fed to an azimuth-over-elevation positioner for pointing to a target towards the pointing direction ̂p.

Following the convention used in most Antenna-related literature, the elevation and azimuth are 0° in the direction of the +Z axis of the reference frame.

Assuming `u`, `v`, and `w` to be direction cosines of the pointing versor `̂p`, their relation with the `Az` and `El` angles is:
- `u = -sin(Az)`
- `v = cos(Az) * sin(El)`
- `w = cos(Az) * cos(El)`

!!! note
The equations above are used to represent the "Azimuth over Elevation" coordinates in GRASP. Some textbooks, however, use the opposite convention, meaning that the same equations (with a possible flip in the az/u sign) are used to describe an "Elevation over Azimuth" coordinate system. This is for example the case in the book _"Theory and Practice of Modern Antenna Range Measurements"_ by Clive Parini et al.

# Fields
- `az::Deg{T}: The azimuth angle in degrees, constrained to be in the [-180°, 180°] range.`
- `el::Deg{T}: The elevation angle in degrees, constrained to be in the [-90°, 90°] range.`

!!! note
The fields of `AzOverEl` objects can also be accessed via `getproperty` using the `azimuth` and `elevation` aliases.
"""
struct AzOverEl{T} <: AngularPointing{T}
    az::Deg{T}
    el::Deg{T}

    BasicTypes.constructor_without_checks(::Type{AzOverEl{T}}, az::Deg, el::Deg) where {T} = new{T}(az, el)
end

### ElOverAz ###
"""
    ElOverAz{T} <: AngularPointing{T}

Object specifying a pointing direction in "Elevation over Azimuth" coordinates, which specify the azimuth and elevation angles that needs to be fed to an elevation-over-azimuth positioner for pointing to a target towards the pointing direction ̂p.

Following the convention used in most Antenna-related literature, the elevation and azimuth are 0° in the direction of the +Z axis of the reference frame.

Assuming `u`, `v`, and `w` to be direction cosines of the pointing versor `̂p`, their relation with the `El` and `Az` angles is:
- `u = -sin(Az) * cos(El)`
- `v = sin(El)`
- `w = cos(Az) * cos(El)`

!!! note
The equations above are used to represent the "Elevation over Azimuth" coordinates in GRASP. Some textbooks, however, use the opposite convention, meaning that the same equations (with sometimes an additional flip in the az/u sign) are used to describe an "Azimuth over Elevation" coordinate system. This is for example the case in the book _"Theory and Practice of Modern Antenna Range Measurements"_ by Clive Parini et al.

# Fields
- `az::Deg{T}: The azimuth angle in degrees, constrained to be in the [-180°, 180°] range.`
- `el::Deg{T}: The elevation angle in degrees, constrained to be in the [-90°, 90°] range.`

!!! note
The fields of `ElOverAz` objects can also be accessed via `getproperty` using the `azimuth` and `elevation` aliases.

See also: [`AzOverEl`](@ref), [`ThetaPhi`](@ref), [`PointingVersor`](@ref), [`UV`](@ref)
"""
struct ElOverAz{T} <: AngularPointing{T}
    az::Deg{T}
    el::Deg{T}

    BasicTypes.constructor_without_checks(::Type{ElOverAz{T}}, az::Deg, el::Deg) where T = new{T}(az, el)
end