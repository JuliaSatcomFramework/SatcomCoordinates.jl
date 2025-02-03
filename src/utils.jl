numbertype(::Type{<:Quantity{T}}) where T  = T
numbertype(::Type{T}) where T <: Real = T
numbertype(::T) where T = numbertype(T)
numbertype(T::DataType) = error("The numbertype function is not implemented for type $T")
numbertype(::Type{<:AbstractSatcomCoordinate{T}}) where T = T
numbertype(T::Type{<:AbstractSatcomCoordinate}) = error("The provided UnionAll type $T does not have the numbertype parameter specified")
numbertype(::Type{<:AbstractArray{T}}) where T = T
numbertype(::Type{<:AbstractCRSTransform{T}}) where T = T

numcoords(::Type{<:AbstractSatcomCoordinate{<:Any, N}}) where N = N
numcoords(T::DataType) = error("The numcoords function is not implemented for type $T")
numcoords(::T) where T = numcoords(T)

"""
    az, el = wrap_spherical_angles_normalized(az::T, el::T, ::Type{<:ThetaPhi}) where T <: Deg{<:Real}
    θ, φ = wrap_spherical_angles_normalized(θ::T, φ::T, ::Type{<:Union{AzOverEl, ElOverAz}}) where T <: Deg{<:Real}

Function that takes as input two angles representing two orthogonal angular components of spherical coordinates (e.g. θ/φ, el/az, etc.) and returns two angles normalized to a consistent wrapping identifying the full sphere:
- `θ/φ` angles are wrapped such that `θ ∈ [0°, 180°]` and `φ ∈ [-180°, 180°]`
- `el/az` angles are wrapped such that `el ∈ [-90°, 90°]` and `az ∈ [-180°, 180°]`

!!! note
    This function already assumes that the provided input angles are already normalized such that both are in the [-180°, 180°] range. If you want to normalize the inputs automatically use the `wrap_first_angle` function.
"""
wrap_spherical_angles_normalized(az::T, el::T, ::Type{<:Union{AzOverEl, ElOverAz, AER, AzEl}}) where {T <: Deg{<:Real}} =
    ifelse(
        abs(el) <= 90°,  # Condition
        (az, el), # First angle is already between -90° and 90°
        (az - copysign(180°,az), el - copysign(180°,el)) # Need to wrap
    )

wrap_spherical_angles_normalized(θ::T, φ::T, ::Type{<:ThetaPhi}) where {T <: Deg{<:Real}} =
    ifelse(
        θ >= 0°,  # Condition
        (θ, φ), # First angle is already between -90° and 90°
        (-θ, φ - copysign(180°,φ)) # Need to wrap
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


# This is inspired from StaticArrays. These are not onlineners as coverage otherwise do not catch them.
has_numbertype(::Type{<:Union{AbstractSatcomCoordinate{T}, AbstractCRSTransform{T}}}) where {T} = return true
has_numbertype(::Type{<:Union{AbstractSatcomCoordinate, AbstractCRSTransform}}) = return false

"""
    enforce_numbertype(input_type, [default_numbertype]) where {C <: Union{AbstractSatcomCoordinate, AbstractCRSTransform}}

Function that takes as input a type and returns a potentialy more specialized subtype of the input type with the numbertype parameter set if not specified in `input_type`. Optionally, this function accepts a secon type (or value) as argument and infers the numbertype to set as default (if not alredy present).
The default numbertype when the function is called with 1-argument is `Float64`.

# Examples
```julia
enforce_numbertype(UV) == UV{Float64} # Provide a default as not present in input type
enforce_numbertype(UV{Float32}) == UV{Float32} # Returns the same input type as it already has a numbertype
enforce_numbertype(UV, Float32) == UV{Float32} # Provide a custom default as not present in input type
enforce_numbertype(UV, 1) == UV{Int64} # Provide a custom default as not present in input type
```
"""
enforce_numbertype(::Type{C}, ::Type{T}) where {C <: Union{AbstractSatcomCoordinate, AbstractCRSTransform}, T} =
    has_numbertype(C) ? C : C{T}
enforce_numbertype(::Type{C}, default = 1.0) where {C <: Union{AbstractSatcomCoordinate, AbstractCRSTransform}} =
    enforce_numbertype(C, numbertype(default))


"""
    to_svector(coord::AbstractSatcomCoordinate)

Generate the unitless SVector containing the _normalized_ fields of the provided coordinate.

!!! note
    By _normalized_ we mean that fields containing Uniftul quantities are stripped of their units and in the case of `Deg` fields, they are converted to radians as trig functions are faster for radians inputs.

See also [`raw_nt`](@ref)
"""
function to_svector(coords::C) where C <: AbstractSatcomCoordinate
    raw_nt(coords) |> Tuple |> SVector{3, numbertype(C)}
end

"""
    raw_nt(coords::AbstractSatcomCoordinate)
Generated a NamedTuple from the provided Object which has the same names as the object fields but contains _normalized_ values of its fields

!!! note
    By _normalized_ we mean that fields containing Uniftul quantities are stripped of their units and in the case of `Deg` fields, they are converted to radians as trig functions are faster for radians inputs.

See also [`to_svector`](@ref)
"""
function raw_nt(coords::C) where C <: AbstractSatcomCoordinate
    nt = @inline getfields(coords)
    map(normalize_value, nt)
end

# Internal function used to strip unit from field values and convert degress to radians
function normalize_value(val::PS)
    if val isa Deg
        stripdeg(val)
    elseif val isa Union{Met, Rad}
        ustrip(val)
    else
        val
    end
end