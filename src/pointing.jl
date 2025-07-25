##################################################################
########                 Type Definitions                 ########
##################################################################

# UV
"""
    UV{CRS <: AbstractCartesianCRS} <: AbstractPointingCRS{CRS}

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

# Properties/Units/Aliases
- `u` => NoUnits
- `v` => NoUnits

See also: [`AbstractPointingCRS`](@ref), [`ThetaPhi`](@ref)
"""
struct UV{CRS <: AbstractCartesianCRS} <: AbstractPointingCRS{CRS} 
    wrapped_crs::CRS
end

# ThetaPhi
"""
    ThetaPhi{CRS <: AbstractCartesianCRS} <: AbstractPointingCRS{CRS}

An object specifying a pointing direction in ThetaPhi coordinates over the spherical CRS `CRS`, defined as the θ and φ in
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

See also: [`PointingVersor`](@ref), [`UV`](@ref)
"""
struct ThetaPhi{CRS <: AbstractCartesianCRS} <: AbstractPointingCRS{CRS} 
    wrapped_crs::CRS
end 

"""
    AzOverEl{CRS <: AbstractCartesianCRS} <: AbstractPointingCRS{CRS}

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
struct AzOverEl{CRS <: AbstractCartesianCRS} <: AbstractPointingCRS{CRS} 
    wrapped_crs::CRS
end

"""
    ElOverAz{CRS <: AbstractCartesianCRS} <: AbstractPointingCRS{CRS}

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
struct ElOverAz{CRS <: AbstractCartesianCRS} <: AbstractPointingCRS{CRS} 
    wrapped_crs::CRS
end

"""
    AzEl{CRS <: AbstractCartesianCRS} <: AbstractPointingCRS{CRS}

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
struct AzEl{CRS <: AbstractCartesianCRS} <: AbstractPointingCRS{CRS} 
    wrapped_crs::CRS
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

const UV_CONSTRUCTOR_TOLERANCE = Ref{Float64}(1e-5)

function process_unitless_coords(::Type{P}, crs::AbstractPointingCRS, coords::NTuple{<:Any, T}) where {P <: Pointing, T}
    PT = typeof(crs)
    tup = map(coords) do val
        rem2pi(deg2rad(val), RoundNearest)
    end
    raw = if PT <: UV
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
        (u, v)
    else
        wrap_spherical_angles_rad_normalized(tup..., PT)
    end
    return constructor_without_checks(Pointing{PT, T}, crs, raw)
end

# This is the default no-arg constructor for any pointing CRS. It falls back to use the `default_wrappedcrs` function to get the default wrapped CRS for the specific CRS type.
function (CRS::Type{<:AbstractPointingCRS})()
    # This is the no-arg constructor, it creates a pointing CRS with the default wrapped CRS
    return CRS(default_wrappedcrs(CRS))
end
for T in (Vararg{Number, 2}, Point{2, Number})
    @eval function (CRS::Type{<:AbstractPointingCRS})(coords::$T)
        # This is the constructor with coordinates, it creates a pointing CRS with the default wrapped CRS and the provided coordinates
        return CRS(default_wrappedcrs(CRS), coords...)
    end

    @eval function (CRS::Type{<:AbstractPointingCRS})(wrapped_crs::AbstractCartesianCRS, coords::$T)
        crs = CRS(wrapped_crs)
        return Pointing(crs, coords)
    end
end


###################################################################
########                  Other Helpers                    ########
###################################################################

# This function returns the type of the pointing CRS for a given CRS type. It is used to get the type of the pointing CRS from a CRS type.
pointingcrs(P::Type{<:AbstractPointingCRS}) = P
pointingcrs(crs::AbstractCRS) = pointingcrs(typeof(crs))

default_wrappedcrs(::Type{<:AbstractPointingCRS{CRS}}) where CRS <: AbstractCartesianCRS = CRS()
default_wrappedcrs(::Type{<:AbstractPointingCRS{<:Any}}) = Cartesian()