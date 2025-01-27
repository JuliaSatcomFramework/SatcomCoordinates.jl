numbertype(::Type{Quantity{T}}) where T  = T
numbertype(::Type{T}) where T <: Number = T
numbertype(::T) where T = numbertype(T)
# numbertype(::Type{FieldVectorCoordinate{<:Any, T}}) where T = T
# numbertype(::Type{LengthCartesian{<:Any, T}}) where T = T
# numbertype(::Type{NonSVectorCoordinate{<:Any, T}}) where T = T
# numbertype(::Type{AngularPointing{T}}) where T = T
# numbertype(::Type{PointingVersor{T}}) where T = T
# numbertype(::Type{UV{T}}) where T = T

"""
    a, b = wrap_first_angle_normalized(α::T, β::T) where T <: Deg{<:Real}

Function that takes as input two angles representing two orthogonal angular components of spherical coordinates (e.g. θ/φ, el/az, etc.) and returns two angles `a` and `b` which represent the same direction but ensures that `a ∈ [-90°, 90°]` and `b ∈ [-180°, 180°]`.

!!! note
    This function already assumes that the provided input angles are already normalized such that both `α` and `β` are in the [-180°, 180°] range. If you want to normalize the inputs automatically use the `wrap_first_angle` function.
"""
wrap_first_angle_normalized(α::T, β::T) where T <: Deg{<:Real} =
    ifelse(
        abs(α) <= 90°,  # Condition
        (α, β), # First angle is already between -90° and 90°
        (α - 180° * sign(α), β - 180° * sign(β)) # Need to wrap
    )

"""
    a, b = wrap_first_angle(α::ValidAngle, β::ValidAngle)

Function that takes as input two angles representing two orthogonal angular components of spherical coordinates (e.g. θ/φ, el/az, etc.) and returns two angles `a` and `b` which represent the same direction but ensures that `a ∈ [-90°, 90°]` and `b ∈ [-180°, 180°]`.

!!! 
"""
wrap_first_angle(α::ValidAngle, β::ValidAngle) = wrap_first_angle_normalized(to_degrees(α, RoundNearest), to_degrees(β, RoundNearest))
wrap_first_angle(p::Point2D) = wrap_first_angle(p[1], p[2])
