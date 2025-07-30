##################################################################
########                 Type Definitions                 ########
##################################################################

# UV
"""
    UV{CRS <: AbstractCRS} <: Abstract2DPointingCRS{CRS}

Specify a pointing direction in UV coordinates over the cartesian CRS `CRS` (which must be a Cartesian CRS). 
U,V Coordinates are equivalent to the direction cosines with respect to the `X` and `Y` axis of the reference frame `CRS`. They can also be related to the spherical coordinates (ISO/Physics) [spherical coordinates
representation](https://en.wikipedia.org/wiki/Spherical_coordinate_system) by the following equations:
- `u = sin(θ) * cos(φ)`
- `v = sin(θ) * sin(φ)`

!!! note
    UV coordinates can only be used to represent pointing direction in the
    half-hemisphere containing the cartesian +Z axis.

!!! note
    The inputs values must also satisfy `u^2 + v^2 <= 1 + SatcomCoordinates.UV_CONSTRUCTOR_TOLERANCE[]` or an error will be thrown. The `SatcomCoordinates.UV_CONSTRUCTOR_TOLERANCE` is a `Ref{Float64}` which defaults to 1e-5 (In case `u^2 + v^2 > 1` the inputs are normalized to ensure `u^2 + v^2 = 1`).

# Properties/Units/Aliases
- `u` => NoUnits
- `v` => NoUnits

See also: [`AbstractPointingCRS`](@ref), [`ThetaPhi`](@ref)
"""
struct UV{CRS <: AbstractCRS} <: Abstract2DPointingCRS{CRS} 
    wrapped_crs::CRS
    function UV{CRS}(wrapped_crs::CRS) where CRS <: AbstractCRS
        check_cartesian_wrapped(UV, wrapped_crs)
        return new{CRS}(wrapped_crs)
    end
end
UV(wrapped_crs::AbstractCRS) = UV{typeof(wrapped_crs)}(wrapped_crs)

# ThetaPhi
"""
    ThetaPhi{CRS <: AbstractCRS} <: Abstract2DPointingCRS{CRS}

An object specifying a pointing direction in ThetaPhi coordinates over the Cartesian CRS `CRS`, defined as the θ and φ in
the (ISO/Physics definition) [spherical coordinates
representation](https://en.wikipedia.org/wiki/Spherical_coordinate_system) 

Assuming `u`, `v`, and `w` to be direction cosines of the pointing versor `̂p`, their relation with the `θ` and `φ` angles is:
- `u = sin(θ) * cos(φ)`
- `v = sin(θ) * sin(φ)`
- `w = cos(θ)`

# Properties/Units/Aliases
- `θ` => u"°" => (theta, t): The polar angle
- `φ` => u"°" => (phi, p, ϕ): The azimuthal angle

While the field name use the greek letters, the specific fields of an arbitrary
`ThetaPhi` object `tp` can be accessed with alternative symbols:
- `tp.θ`, `tp.theta` and `tp.t` can be used to access the `θ` field
- `tp.φ`, `tp.ϕ`, `tp.phi` and `tp.p` can be used to access the `φ` field

See also: [`DirectionCosines`](@ref), [`UV`](@ref)
"""
struct ThetaPhi{CRS <: AbstractCRS} <: Abstract2DPointingCRS{CRS} 
    wrapped_crs::CRS
    function ThetaPhi{CRS}(wrapped_crs::CRS) where CRS <: AbstractCRS
        check_cartesian_wrapped(ThetaPhi, wrapped_crs)
        return new{CRS}(wrapped_crs)
    end
end 
ThetaPhi(wrapped_crs::AbstractCRS) = ThetaPhi{typeof(wrapped_crs)}(wrapped_crs)

"""
    AzOverEl{CRS <: AbstractCRS} <: Abstract2DPointingCRS{CRS}

Object specifying a pointing direction in "Azimuth over Elevation" coordinates, which specify the elevation and azimuth angles that needs to be fed to an azimuth-over-elevation positioner for pointing to a target towards the pointing direction ̂p.

Following the convention used in most Antenna-related literature, the elevation and azimuth are 0° in the direction of the +Z axis of the reference frame.

Assuming `u`, `v`, and `w` to be direction cosines of the pointing versor `̂p`, their relation with the `Az` and `El` angles is:
- `u = -sin(Az)`
- `v = cos(Az) * sin(El)`
- `w = cos(Az) * cos(El)`

!!! note
    The equations above are used to represent the "Azimuth over Elevation" coordinates in GRASP. Some textbooks, however, use the opposite convention, meaning that the same equations (with a possible flip in the az/u sign) are used to describe an "Elevation over Azimuth" coordinate system. This is for example the case in the book _"Theory and Practice of Modern Antenna Range Measurements"_ by Clive Parini et al.

# Properties/Units/Aliases
- `az` => u"°" => (azimuth,)
- `el` => u"°" => (elevation,)

!!! note
    The fields of `AzOverEl` objects can also be accessed via `getproperty` using the `azimuth` and `elevation` aliases.
"""
struct AzOverEl{CRS <: AbstractCRS} <: Abstract2DPointingCRS{CRS} 
    wrapped_crs::CRS
    function AzOverEl{CRS}(wrapped_crs::CRS) where CRS <: AbstractCRS
        check_cartesian_wrapped(AzOverEl, wrapped_crs)
        return new{CRS}(wrapped_crs)
    end
end
AzOverEl(wrapped_crs::AbstractCRS) = AzOverEl{typeof(wrapped_crs)}(wrapped_crs)

"""
    ElOverAz{CRS <: AbstractCRS} <: Abstract2DPointingCRS{CRS}

Object specifying a pointing direction in "Elevation over Azimuth" coordinates, which specify the azimuth and elevation angles that needs to be fed to an elevation-over-azimuth positioner for pointing to a target towards the pointing direction ̂p.

Following the convention used in most Antenna-related literature, the elevation and azimuth are 0° in the direction of the +Z axis of the reference frame.

Assuming `u`, `v`, and `w` to be direction cosines of the pointing versor `̂p`, their relation with the `El` and `Az` angles is:
- `u = -sin(Az) * cos(El)`
- `v = sin(El)`
- `w = cos(Az) * cos(El)`

!!! note
    The equations above are used to represent the "Elevation over Azimuth" coordinates in GRASP. Some textbooks, however, use the opposite convention, meaning that the same equations (with sometimes an additional flip in the az/u sign) are used to describe an "Azimuth over Elevation" coordinate system. This is for example the case in the book _"Theory and Practice of Modern Antenna Range Measurements"_ by Clive Parini et al.

# Properties/Units/Aliases
- `az` => u"°" => (azimuth,)
- `el` => u"°" => (elevation,)

See also: [`AzOverEl`](@ref), [`ThetaPhi`](@ref), [`UV`](@ref)
"""
struct ElOverAz{CRS <: AbstractCRS} <: Abstract2DPointingCRS{CRS} 
    wrapped_crs::CRS
    function ElOverAz{CRS}(wrapped_crs::CRS) where CRS <: AbstractCRS
        check_cartesian_wrapped(ElOverAz, wrapped_crs)
        return new{CRS}(wrapped_crs)
    end
end
ElOverAz(wrapped_crs::AbstractCRS) = ElOverAz{typeof(wrapped_crs)}(wrapped_crs)

"""
    AzEl{CRS <: AbstractCRS} <: Abstract2DPointingCRS{CRS}

Object specifying a pointing direction in "Elevation/Azimuth" coordinates, defined following the convention used for Azimuth-Elevation-Range ([`AER`](@ref)) coordinates used by MATLAB and by this package.

This represents the azimuth/elevation definition often used for describing pointing from a user terminal on ground towards a satellite. They are very similar to the `ElOverAz` definition but with a rotation of the underlying CRS such that elevation is 90° in the direction of the +Z axis and azimuth is computed on the XY plane from the +Y axis towards the +X axis.

Assuming `u`, `v`, and `w` to be direction cosines of the pointing versor `̂p`, their relation with the `El` and `Az` angles is:
- `u = cos(El) * sin(Az)`
- `v = cos(El) * cos(Az)`
- `w = sin(El)`

# Properties/Units/Aliases
- `az` => u"°" => (azimuth,)
- `el` => u"°" => (elevation,)

See also: [`ThetaPhi`](@ref), [`UV`](@ref), [`ElOverAz`](@ref), [`AzOverEl`](@ref)
"""
struct AzEl{CRS <: AbstractCRS} <: Abstract2DPointingCRS{CRS} 
    wrapped_crs::CRS
    function AzEl{CRS}(wrapped_crs::CRS) where CRS <: AbstractCRS
        check_cartesian_wrapped(AzEl, wrapped_crs)
        return new{CRS}(wrapped_crs)
    end
end
AzEl(wrapped_crs::AbstractCRS) = AzEl{typeof(wrapped_crs)}(wrapped_crs)

struct DirectionCosines{CRS <: AbstractCRS} <: AbstractPointingCRS{CRS} 
    wrapped_crs::CRS
    function DirectionCosines{CRS}(wrapped_crs::CRS) where CRS <: AbstractCRS
        check_cartesian_wrapped(DirectionCosines, wrapped_crs)
        return new{CRS}(wrapped_crs)
    end
end
DirectionCosines(wrapped_crs::AbstractCRS) = DirectionCosines{typeof(wrapped_crs)}(wrapped_crs)

##################################################################
########                  CRS Properties                  ########
##################################################################

# Here we define the properties for each of the pointing types CRSs
@define_properties ThetaPhi [
    θ => u"°" => (theta, t)
    φ => u"°" => (phi, p, ϕ)
]

@define_properties UV [
    u => NoUnits
    v => NoUnits
]

for PT in (:AzOverEl, :ElOverAz, :AzEl)
    @eval @define_properties $PT [
        az => u"°" => (azimuth,)
        el => u"°" => (elevation,)
    ]
end 

@define_properties DirectionCosines [
    u => NoUnits
    v => NoUnits
    w => NoUnits
]

###################################################################
########               Constructors/Helpers                ########
###################################################################

# This function is used to wrap angles going beyond the [-180°, 180°] range to provide consistent 2-angle representation of any point on the sphere (and depending on the specific pointing CRS)
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

process_unitless_coords(::Type{<:FieldOrCoordinate}, crs::AbstractPointingCRS, coords::NTuple{<:Any, <:Any}) = throw(ArgumentError("It is currently not possible to create coordinates other than `Pointing` with a reference CRS which is a subtype of `AbstractPointingCRS`"))

function process_unitless_coords(::Type{<:Coordinate}, crs::AbstractPointingCRS, coords::NTuple{2,T}) where {T}
    PT = typeof(crs)
    tup = map(coords) do val
        rem2pi(val, RoundNearest)
    end
    return wrap_spherical_angles_rad_normalized(tup..., PT)
end

const UV_CONSTRUCTOR_TOLERANCE = Ref{Float64}(1e-5)

function process_unitless_coords(::Type{<:Coordinate}, crs::UV, coords::NTuple{2,T}) where {T}
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

function process_unitless_coords(::Type{P}, crs::DirectionCosines, coords::NTuple{3,T}) where {P<:Pointing,T}
    return coords ./ hypot(coords...)
end

# This is the default no-arg constructor for any pointing CRS. It falls back to use the `default_wrappedcrs` function to get the default wrapped CRS for the specific CRS type.
function (CRS::Type{<:AbstractPointingCRS})()
    # This is the no-arg constructor, it creates a pointing CRS with the default wrapped CRS
    return CRS(default_wrappedcrs(CRS))
end

###################################################################
########                  Other Helpers                    ########
###################################################################

# This function returns the type of the pointing CRS for a given CRS type. It is used to get the type of the pointing CRS from a CRS type.
pointingcrs(P::Type{<:AbstractPointingCRS}) = P
pointingcrs(crs::AbstractCRS) = pointingcrs(typeof(crs))

function default_wrappedcrs(D::Type{<:AbstractPointingCRS{CRS}}) where CRS <: AbstractCRS
    wrapped = CRS()
    check_cartesian_wrapped(D, wrapped)
    return wrapped
end

##### Conversions #####
"""
    abstract type PointingTransform <: AbstractRawCRSTransform end

Abstract type for all transformations that used to convert between a 2D pointing CRS to the DirectionCosines one (and vice-versa).

These are **raw** transforms and are also used to go to map to the 
"""
abstract type PointingTransform <: AbstractRawCRSTransform end

struct AngularPointingToDirectionCosines{PT <: Abstract2DPointingCRS} <: PointingTransform end
struct DirectionCosinesToAngularPointing{PT <: Abstract2DPointingCRS} <: PointingTransform end

ncoords_in(::Type{<:AngularPointingToDirectionCosines{PT}}) where PT = 2
ncoords_out(::Type{<:AngularPointingToDirectionCosines{PT}}) where PT = 3
ncoords_in(::Type{<:DirectionCosinesToAngularPointing{PT}}) where PT = 3
ncoords_out(::Type{<:DirectionCosinesToAngularPointing{PT}}) where PT = 2

TransformsBase.isinvertible(::Type{<:PointingTransform}) = true
TransformsBase.isrevertible(::Type{<:PointingTransform}) = true

function raw_linkedcrs_transform(::AbstractPointingCRS)
    throw(ArgumentError("It is not possible to go from a Pointing CRS to its linked Cartesian CRS as the information about the distance from the origin is lost"))
end

# Generic implementation for the transform_tuplecoords

# UV <-> DirectionCosines
function TransformsBase.apply(::AngularPointingToDirectionCosines{<:UV}, tup::NTuple{2, <:AbstractFloat})
    u, v = tup
    w = sqrt(1 - u^2 - v^2)
    return (u, v, w), nothing
end
function TransformsBase.apply(::DirectionCosinesToAngularPointing{<:UV}, tup::NTuple{3, <:AbstractFloat})
    u, v, w = tup
    w >= 0 || throw(ArgumentError("The provided values in the `DirectionCosines` CRS are not valid as they are located in the half-hemisphere containing the cartesian -Z axis and can not be converted to UV coordinates"))
    return (u, v), nothing
end

# ThetaPhi <-> UV (Specific implementation for slightly faster conversion)
function transform_tuplecoords(::UV{CRS}, ::ThetaPhi{CRS}, tup::NTuple{2, <:AbstractFloat}) where CRS <: AbstractCRS
    θ, φ = tup
	θ <= π/2 || throw(ArgumentError("The provided ThetaPhi coordinate has θ > 90° so it lies in the half-hemisphere containing the -Z axis and can not be represented in UV"))
	v, u = sin(θ) .* sincos(φ)
    return (u, v)
end
function transform_tuplecoords(::ThetaPhi{CRS}, ::UV{CRS}, tup::NTuple{2, <:AbstractFloat}) where CRS <: AbstractCRS
    u, v = tup
    θ = asin(sqrt(u^2 + v^2))
    φ = atan(v,u)
    return (θ, φ)
end

# ThetaPhi <-> DirectionCosines
function TransformsBase.apply(::AngularPointingToDirectionCosines{<:ThetaPhi}, tup::NTuple{2, <:AbstractFloat})
    θ, φ = tup
	sθ,cθ = sincos(θ)
	sφ,cφ = sincos(φ)
	u = sθ * cφ
	v = sθ * sφ 
	w = cθ
    return (u, v, w), nothing
end
function TransformsBase.apply(::DirectionCosinesToAngularPointing{<:ThetaPhi}, tup::NTuple{3, <:AbstractFloat})
    (u, v, w) = tup
	θ = acos(w)
	φ = atan(v,u)
    return (θ, φ), nothing
end

# ThetaPhi <-> AzEl
# We can have a much simpler direct conversion between the two without passing by the PointingVersor
function transform_tuplecoords(::AzEl{CRS}, ::ThetaPhi{CRS}, tup::NTuple{2, <:AbstractFloat}) where CRS <: AbstractCRS
    θ, φ = tup
    az = rem2pi(π/2 - φ, RoundNearest)
    el = π/2 - θ # Already in the [-90°, 90°] range
    (az, el)
end
function transform_tuplecoords(::ThetaPhi{CRS}, ::AzEl{CRS}, tup::NTuple{2, <:AbstractFloat}) where CRS <: AbstractCRS
    az, el = tup
    θ = π/2 - el
    φ = rem2pi(π/2 - az, RoundNearest)
    (θ, φ)
end

# AzEl <-> DirectionCosines
#= Conversion from https://gssc.esa.int/navipedia/index.php/Transformations_between_ECEF_and_ENU_coordinates knowing that:
- p̂ ⋅ ê = u
- p̂ ⋅ n̂ = v
- p̂ ⋅ û = w
=#
function TransformsBase.apply(::DirectionCosinesToAngularPointing{<:AzEl}, tup::NTuple{3, <:AbstractFloat})
    u,v,w = tup
    az = atan(u, v) # Already in the [-180°, 180°] range
    el = asin(w) # Already in the [-90°, 90°] range
    return (az, el), nothing
end
function TransformsBase.apply(::AngularPointingToDirectionCosines{<:AzEl}, tup::NTuple{2, <:AbstractFloat})
    az, el = tup
    saz,caz = sincos(az)
    sel,cel = sincos(el)
    u = saz * cel
    v = caz * cel
    w = sel
    return (u, v, w), nothing
end

# ElOverAz <-> DirectionCosines
function TransformsBase.apply(::DirectionCosinesToAngularPointing{<:ElOverAz}, tup::NTuple{3, <:AbstractFloat})
    u,v,w = tup
    az = atan(-u,w) # Already in the [-180°, 180°] range
    el = asin(v) # Already in the [-90°, 90°] range
    return (az, el), nothing
end
function TransformsBase.apply(::AngularPointingToDirectionCosines{<:ElOverAz}, tup::NTuple{2, <:AbstractFloat})
    az, el = tup
    saz,caz = sincos(az)
    sel,cel = sincos(el)
    u = -saz * cel
    v = sel
    w = caz * cel
    return (u, v, w), nothing
end

# AzOverEl <-> DirectionCosines
function TransformsBase.apply(::DirectionCosinesToAngularPointing{<:AzOverEl}, tup::NTuple{3, <:AbstractFloat})
    u, v, w = tup
    el = atan(v/w) # Already returns a value in the range [-90°, 90°]
    az = asin(-u) # This only returns the value in the [-90°, 90°] range
    # Make the angle compatible with our ranges of azimuth and elevation
    az = ifelse(w >= 0, az, copysign(180°, az) - az)
    return (az, el), nothing
end
function TransformsBase.apply(::AngularPointingToDirectionCosines{<:AzOverEl}, tup::NTuple{2, <:AbstractFloat})
    az, el = tup
    sel,cel = sincos(el)
    saz,caz = sincos(az)
    u = -saz
    v = caz * sel
    w = caz * cel
    return (u, v, w), nothing
end

# Conversion fallbacks
# Conversion between non DirectionCosines pointing types, passing through DirectionCosines
function transform_tuplecoords(::DirectionCosines{CRS}, ::PT, tup::NTuple{2, <:AbstractFloat}) where {CRS <: AbstractCRS, PT <: Abstract2DPointingCRS{CRS}}
    pt2dc = AngularPointingToDirectionCosines{PT}()
    pt2dc(tup)
end
function transform_tuplecoords(::PT, ::DirectionCosines{CRS}, tup::NTuple{3, <:AbstractFloat}) where {CRS <: AbstractCRS, PT <: Abstract2DPointingCRS{CRS}}
    dc2pt = DirectionCosinesToAngularPointing{PT}()
    dc2pt(tup)
end
function transform_tuplecoords(crsₒ::AbstractPointingCRS{CRS}, crsᵢ::AbstractPointingCRS{CRS}, tup::NTuple{2, <:AbstractFloat}) where CRS <: AbstractCRS
    dc = DirectionCosines(linkedcrs(crsₒ))
    uvw = transform_tuplecoords(dc, crsᵢ, tup)
    return transform_tuplecoords(crsₒ, dc, uvw)
end

#### Random.rand #####
function rand_tuplecoords(rng::AbstractRNG, ::DirectionCosines, T::Type{<:AbstractFloat})
    tup = ntuple(i -> rand(rng) - .5, 3)
    return map(T, tup ./ hypot(tup...))
end

function rand_tuplecoords(rng::AbstractRNG, crs::UV, T::Type{<:AbstractFloat})
    dc = DirectionCosines(linkedcrs(crs))
    u, v, w = rand_tuplecoords(rng, dc, T)
    return map(T, (u, v))
end

function rand_tuplecoords(rng::AbstractRNG, ::ThetaPhi, T::Type{<:AbstractFloat})
    θ = rand(rng) * π
    φ = rand(rng) * 2π - π
    return map(T, (θ, φ))
end

function rand_tuplecoords(rng::AbstractRNG, ::Union{AzOverEl, ElOverAz, AzEl}, T::Type{<:AbstractFloat})
    az = rand(rng) * 2π - π
    el = rand(rng) * π - π/2
    return map(T, (az, el))
end