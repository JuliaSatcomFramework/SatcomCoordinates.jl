"""
    struct PointingOffset{P, T} <: AbstractPointingOffset{T}

Type used to describe an offset between two pointing directions.

!!! note
    The `P` parameter must be a subtype of `Union{UV, AngularPointing}` but must be the basic pointing type without specific numbertype (e.g. `UV` rather than `UV{Float64}`) as the numbertype is already tracked by the `T` parameter within the `PointingOffset` type.
"""
struct PointingOffset{P <: Union{UV, AngularPointing}, T} <: AbstractPointingOffset{T}
    svector::SVector{2, T}

    BasicTypes.constructor_without_checks(::Type{PointingOffset{P, T}}, svector::SVector{2, T}) where {P <: Union{UV, AngularPointing}, T} = new{P, T}(svector)
end