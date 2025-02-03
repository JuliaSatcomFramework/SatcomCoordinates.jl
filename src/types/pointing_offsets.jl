"""
    struct UVOffset{T} <: AbstractPointingOffset{T}

Type used to describe an offset in UV coordinates.

The UVOffset coordinates must satisfy:
- `sqrt(u^2 + v^2) ≤ 2`

This type is mostly generated indirectly when subtracting two pointing directions expressed in UV.
"""
struct UVOffset{T} <: AbstractPointingOffset{T}
    uv::UV{T}

    BasicTypes.constructor_without_checks(::Type{UVOffset{T}}, uv::UV) where T = new{T}(uv)

    function BasicTypes.constructor_without_checks(::Type{UVOffset{T}}, u, v) where T
        uv = constructor_without_checks(UV{T}, u, v)
        return constructor_without_checks(UVOffset{T}, uv)
    end
end

"""
    struct ThetaPhiOffset{T} <: AbstractPointingOffset{T}

Type used to describe an angular offset between two pointing directions.

The ThetaPhiOffset coordinates must satisfy:
- `theta ∈ [-90, 90]`
- `phi ∈ [-180, 180]`

This type is mostly used with the [`add_angular_offset`](@ref) and [`get_angular_offset`](@ref) functions.
"""
struct ThetaPhiOffset{T} <: AbstractPointingOffset{T}
    tp::ThetaPhi{T}

    BasicTypes.constructor_without_checks(::Type{ThetaPhiOffset{T}}, tp::ThetaPhi) where T = new{T}(tp)

    function BasicTypes.constructor_without_checks(::Type{ThetaPhiOffset{T}}, theta, phi) where T
        tp = constructor_without_checks(ThetaPhi{T}, theta, phi)
        return constructor_without_checks(ThetaPhiOffset{T}, tp)
    end
end
