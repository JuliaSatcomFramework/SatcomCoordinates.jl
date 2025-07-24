"""
    AbstractPointingType

Abstract type representing any pointing type defined over a 3D Cartesian CRS.
Different pointing types identify different ways of identifying a position on the unitary sphere (over the specified CRS) with two coordinates (e.g. theta/phi, azimuth/elevation, etc.)
"""
abstract type AbstractPointingType end

# UV
"""
    UV <: AbstractPointingType

Specify a pointing direction in UV coordinates over the cartesian CRS `CRS`. 
U,V Coordinates are equivalent to the direction cosines with respect to the `X` and `Y` axis of the reference frame `CRS`. They can also be related to the spherical coordinates (ISO/Physics) [spherical coordinates
representation](https://en.wikipedia.org/wiki/Spherical_coordinate_system) by the following equations:
- `u = sin(θ) * cos(φ)`
- `v = sin(θ) * sin(φ)`

!!! note
    UV coordinates can only be used to represent pointing direction in the
    half-hemisphere containing the cartesian +Z axis.

!!! note
    The inputs values must also satisfy `u^2 + v^2 <= 1 + SatcomCoordinates.UV_CONSTRUCTOR_TOLERANCE[]` or an error will be thrown. The `SatcomCoordinates.UV_CONSTRUCTOR_TOLERANCE` is a `Ref{Float64}` which defaults to 1e-5 (In case `u^2 + v^2 > 1` the inputs are normalized to ensure `u^2 + v^2 = 1`).

# Properties
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
struct UV <: AbstractPointingType end

# ThetaPhi
"""
    ThetaPhi <: AbstractPointingType

An object specifying a pointing direction in ThetaPhi coordinates over the spherical CRS `CRS`, defined as the θ and φ in
the (ISO/Physics definition) [spherical coordinates
representation](https://en.wikipedia.org/wiki/Spherical_coordinate_system) 

Assuming `u`, `v`, and `w` to be direction cosines of the pointing versor `̂p`, their relation with the `θ` and `φ` angles is:
- `u = sin(θ) * cos(φ)`
- `v = sin(θ) * sin(φ)`
- `w = cos(θ)`

# Properties
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
struct ThetaPhi <: AbstractPointingType end

### AzOverEl ###
"""
    AzOverEl <: AbstractPointingType

Object specifying a pointing direction in "Azimuth over Elevation" coordinates, which specify the elevation and azimuth angles that needs to be fed to an azimuth-over-elevation positioner for pointing to a target towards the pointing direction ̂p.

Following the convention used in most Antenna-related literature, the elevation and azimuth are 0° in the direction of the +Z axis of the reference frame.

Assuming `u`, `v`, and `w` to be direction cosines of the pointing versor `̂p`, their relation with the `Az` and `El` angles is:
- `u = -sin(Az)`
- `v = cos(Az) * sin(El)`
- `w = cos(Az) * cos(El)`

!!! note
    The equations above are used to represent the "Azimuth over Elevation" coordinates in GRASP. Some textbooks, however, use the opposite convention, meaning that the same equations (with a possible flip in the az/u sign) are used to describe an "Elevation over Azimuth" coordinate system. This is for example the case in the book _"Theory and Practice of Modern Antenna Range Measurements"_ by Clive Parini et al.

# Properties
- `az::Deg{T}: The azimuth angle in degrees, constrained to be in the [-180°, 180°] range.`
- `el::Deg{T}: The elevation angle in degrees, constrained to be in the [-90°, 90°] range.`

!!! note
    The fields of `AzOverEl` objects can also be accessed via `getproperty` using the `azimuth` and `elevation` aliases.
"""
struct AzOverEl <: AbstractPointingType end

### ElOverAz ###
"""
    ElOverAz <: AbstractPointingType

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
struct ElOverAz <: AbstractPointingType end

"""
    AzEl <: AbstractPointingType

Object specifying a pointing direction in "Elevation/Azimuth" coordinates, defined following the convention used for Azimuth-Elevation-Range ([`AER`](@ref)) coordinates used by MATLAB and by this package.

This represents the azimuth/elevation definition often used for describing pointing from a user terminal on ground towards a satellite. They are very similar to the `ElOverAz` definition but with a rotation of the underlying CRS such that elevation is 90° in the direction of the +Z axis and azimuth is computed on the XY plane from the +Y axis towards the +X axis.

Assuming `u`, `v`, and `w` to be direction cosines of the pointing versor `̂p`, their relation with the `El` and `Az` angles is:
- `u = cos(El) * sin(Az)`
- `v = cos(El) * cos(Az)`
- `w = sin(El)`

# Fields
- `az::Deg{T}: The azimuth angle in degrees, constrained to be in the [-180°, 180°] range.`
- `el::Deg{T}: The elevation angle in degrees, constrained to be in the [-90°, 90°] range.`

!!! note
    The fields of `AzEl` objects can also be accessed via `getproperty` using the `azimuth` and `elevation` aliases.

See also: [`ThetaPhi`](@ref), [`PointingVersor`](@ref), [`UV`](@ref), [`ElOverAz`](@ref), [`AzOverEl`](@ref)
"""
struct AzEl <: AbstractPointingType end

struct PointingCRS{CRS <: AbstractCartesianCRS, PT <: AbstractPointingType} <: AbstractCRS 
    parent_crs::CRS
end
PointingCRS(crs::AbstractCartesianCRS = Cartesian()) = PointingCRS{typeof(crs), ThetaPhi}(crs)
PointingCRS(crs::AbstractCartesianCRS, pt::Type{<:AbstractPointingType}) = PointingCRS{typeof(crs), pt}(crs)

parent_crs(crs::AbstractCRS) = hasfield(typeof(crs), :parent_crs) ? getfield(crs, :parent_crs) : crs

wrap_spherical_angles_rad_normalized(az::T, el::T, ::Type{<:Union{AzOverEl, ElOverAz, AzEl}}) where {T <: AbstractFloat} =
    ifelse(
        abs(el) <= π/2,  # Condition
        (az, el), # Azimuth angle is already between -180° and 180° as it's already been normalized
        (az - copysign(π,az), el - copysign(π,el)) # Need to wrap
    )

wrap_spherical_angles_rad_normalized(θ::T, φ::T, ::Type{<:ThetaPhi}) where {T <: AbstractFloat} =
    ifelse(
        θ >= 0,  # Condition
        (θ, φ), # First angle is already between -90° and 90°
        (-θ, φ - copysign(π,φ)) # Need to wrap
    )

coords_units(::Type{UV}) = (; u = NoUnits, v = NoUnits)
coords_units(::Type{ThetaPhi}) = (; θ = u"°", φ = u"°")
coords_units(::Type{Union{AzOverEl, ElOverAz, AzEl}}) = (; az = u"°", el = u"°")
coords_units(::Type{<:PointingCRS{<:Any, PT}}) where PT = coords_units(PT)

function process_pointing_coords(PT::Type{<:AbstractPointingType}, coords::NTuple{2, <:AbstractFloat})
    tup = map(coords) do val
        rem2pi(deg2rad(val), RoundNearest)
    end
    wrap_spherical_angles_rad_normalized(tup..., PT)
end

const UV_CONSTRUCTOR_TOLERANCE = Ref{Float64}(1e-5)

function process_pointing_coords(::Type{UV}, coords::NTuple{2, <:AbstractFloat})
    u, v = coords
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
    return (u, v)
end
