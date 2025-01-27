numbertype(::Type{Quantity{T}}) where T  = T
numbertype(::Type{T}) where T <: Number = T
numbertype(::T) where T = numbertype(T)
numbertype(T::DataType) = error("The numbertype function is not implemented for type $T")

numbertype(::Type{<:AbstractPointing{T}}) where T = T

"""
    az, el = wrap_spherical_angles_normalized(az::T, el::T, ::Type{<:ThetaPhi}) where T <: Deg{<:Real}
    θ, φ = wrap_spherical_angles_normalized(θ::T, φ::T, ::Type{<:Union{AzOverEl, ElOverAz}}) where T <: Deg{<:Real}

Function that takes as input two angles representing two orthogonal angular components of spherical coordinates (e.g. θ/φ, el/az, etc.) and returns two angles normalized to a consistent wrapping identifying the full sphere:
- `θ/φ` angles are wrapped such that `θ ∈ [0°, 180°]` and `φ ∈ [-180°, 180°]`
- `el/az` angles are wrapped such that `el ∈ [-90°, 90°]` and `az ∈ [-180°, 180°]`

!!! note
    This function already assumes that the provided input angles are already normalized such that both are in the [-180°, 180°] range. If you want to normalize the inputs automatically use the `wrap_first_angle` function.
"""
wrap_spherical_angles_normalized(az::T, el::T, ::Type{<:Union{AzOverEl, ElOverAz}}) where {T <: Deg{<:Real}} =
    ifelse(
        abs(el) <= 90°,  # Condition
        (az, el), # First angle is already between -90° and 90°
        (az - 180° * sign(az), el - 180° * sign(el)) # Need to wrap
    )

wrap_spherical_angles_normalized(θ::T, φ::T, ::Type{<:ThetaPhi}) where {T <: Deg{<:Real}} =
    ifelse(
        θ >= 0°,  # Condition
        (θ, φ), # First angle is already between -90° and 90°
        (-θ, φ - 180° * sign(φ)) # Need to wrap
    )

"""
    az, el = wrap_spherical_angles(az::ValidAngle, el::ValidAngle, ::Type{<:ThetaPhi}) where T <: Deg{<:Real}
    θ, φ = wrap_spherical_angles(θ::ValidAngle, φ::ValidAngle, ::Type{<:Union{AzOverEl, ElOverAz}}) where T <: Deg{<:Real}

Function that takes as input two angles representing two orthogonal angular components of spherical coordinates (e.g. θ/φ, el/az, etc.) and returns two angles normalized to a consistent wrapping identifying the full sphere:
- `θ/φ` angles are wrapped such that `θ ∈ [0°, 180°]` and `φ ∈ [-180°, 180°]`
- `el/az` angles are wrapped such that `el ∈ [-90°, 90°]` and `az ∈ [-180°, 180°]`

!!! 
"""
wrap_spherical_angles(α::ValidAngle, β::ValidAngle, ::Type{T}) where T <: Union{ThetaPhi, AzOverEl, ElOverAz} = wrap_spherical_angles_normalized(to_degrees(α, RoundNearest), to_degrees(β, RoundNearest), T)
wrap_spherical_angles(p::Point2D, ::Type{T}) where T <: Union{ThetaPhi, AzOverEl, ElOverAz} = wrap_spherical_angles(p[1], p[2], T)


# This is inspired from StaticArrays
Base.@pure has_eltype(::Type{<:AbstractPointing{T}}) where {T} = @isdefined T
has_eltype(::Type{<:AbstractPointing}) = false
