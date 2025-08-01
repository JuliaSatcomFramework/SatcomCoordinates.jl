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

!!! note "Valid Directions"
    UV coordinates can only be used to represent pointing direction in the
    half-hemisphere containing the cartesian +Z axis.

!!! note "Constructor Tolerance"
    The inputs values must also satisfy `u^2 + v^2 <= 1 + SatcomCoordinates.UV_CONSTRUCTOR_TOLERANCE[]` or an error will be thrown. The `SatcomCoordinates.UV_CONSTRUCTOR_TOLERANCE` is a `Ref{Float64}` which defaults to 1e-5 (In case `u^2 + v^2 > 1` the inputs are normalized to ensure `u^2 + v^2 = 1`).

# Properties/Units/Aliases
- `u` => NoUnits
- `v` => NoUnits

See also: [`AbstractPointingCRS`](@ref), [`ThetaPhi`](@ref)
"""
struct UV{CRS <: AbstractCRS} <: Abstract2DPointingCRS{CRS} 
    wrapped_crs::CRS
    function UV(wrapped_crs::CRS) where CRS <: AbstractCRS
        check_cartesian_wrapped(UV, wrapped_crs)
        return new{CRS}(wrapped_crs)
    end
end

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
    function ThetaPhi(wrapped_crs::CRS) where CRS <: AbstractCRS
        check_cartesian_wrapped(ThetaPhi, wrapped_crs)
        return new{CRS}(wrapped_crs)
    end
end 

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
    function AzOverEl(wrapped_crs::CRS) where CRS <: AbstractCRS
        check_cartesian_wrapped(AzOverEl, wrapped_crs)
        return new{CRS}(wrapped_crs)
    end
end

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
    function ElOverAz(wrapped_crs::CRS) where CRS <: AbstractCRS
        check_cartesian_wrapped(ElOverAz, wrapped_crs)
        return new{CRS}(wrapped_crs)
    end
end

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
    function AzEl(wrapped_crs::CRS) where CRS <: AbstractCRS
        check_cartesian_wrapped(AzEl, wrapped_crs)
        return new{CRS}(wrapped_crs)
    end
end

struct DirectionCosines{CRS <: AbstractCRS} <: AbstractPointingCRS{CRS} 
    wrapped_crs::CRS
    function DirectionCosines(wrapped_crs::CRS) where CRS <: AbstractCRS
        check_cartesian_wrapped(DirectionCosines, wrapped_crs)
        return new{CRS}(wrapped_crs)
    end
end

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
    u => NoUnits => (x,)
    v => NoUnits => (y,)
    w => NoUnits => (z,)
]