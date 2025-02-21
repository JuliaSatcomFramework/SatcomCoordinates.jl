#### Numbertype interface ####
"""
    numbertype(T::Type)
    numbertype(::T)

This function shall return the underlying numbertype of the provided Type or object.

The concept of numbertype is defined here as the subtype of `Real` which is used to represent the numerical values in the object's field.
It is not directly the type of the fields, mainly as we consider fields of type `Unitul.Quantity{T}` to have numbertype `T`.

All the types defined in this package have an assciated parametric numbertype as first parameter.

See also [`enforce_numbertype`](@ref), [`change_numbertype`](@ref), [`has_numbertype`](@ref), [`default_numbertype`](@ref)
"""
function numbertype end

"""
    has_numbertype(T::Type)
    has_numbertype(::T)

This function shall return `true` if the provided type `T` or object of type `T` has an associated numbertype.

This function will return `false` for types defined within this package that do not have the numbertype parameter specified (type `T` is thus a `UnionAll` on the numbertype parameter).
"""
function has_numbertype end

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

See also [`numbertype`](@ref), [`enforce_numbertype`](@ref), [`has_numbertype`](@ref), [`default_numbertype`](@ref)
"""
function enforce_numbertype end

"""
    change_numbertype(T::Type, x) 

Functions that change the underlying numbertype of the provided object `x` to the first argument `T`.

It has a fallback default implementation for types defined within this package which calls `convert` on the provided object `x` to the type `basetype(x){T}`.

See also [`numbertype`](@ref), [`enforce_numbertype`](@ref), [`has_numbertype`](@ref), [`default_numbertype`](@ref)
"""
function change_numbertype end

"""
    default_numbertype(args...)

Function that returns the common valid numbertype among the arguments provided as input. It finds the common numbertype via `promote_type` and either return that (if it's a subtype of `AbstractFloat`) or `Float64` if it's not.

This function is useful to automatically extract from inputs the `numbertype` to use in constructors.

See also [`numbertype`](@ref), [`enforce_numbertype`](@ref), [`has_numbertype`](@ref), [`change_numbertype`](@ref)
"""
function default_numbertype(args::Vararg{Any, N}) where N
    T = promote_type(map(numbertype, args)...)
    T <: AbstractFloat ? T : Float64
end

"""
    raw_svector(coord::AbstractSatcomCoordinate)

Extracts the raw `SVector` storing the data for the provided coordinate. This assumes that `coord` has a field called `svector` and just calls `getfield(coord, :svector)`.

Concrete subtypes that do not follow this convention should overload this function.


See also [`raw_properties`](@ref)
"""
raw_svector(coords::AbstractSatcomCoordinate) = return getfield(coords, :svector)

"""
    raw_properties(coords::AbstractSatcomCoordinate)
Generate a NamedTuple starting from the raw `SVector` holding the coords data and assigning a label to each valid property of the coordinate (as defined by the `Base.propertynames(coords)` function).

See also [`raw_svector`](@ref)
"""
function raw_properties(coords::AbstractSatcomCoordinate)
    nms = propertynames(coords)
    svector = raw_svector(coords)
    return NamedTuple{nms}(Tuple(svector))
end

##### Misc Utilities ####

"""
    az, el = wrap_spherical_angles_normalized(az::T, el::T, ::Type{<:ThetaPhi}) where T <: Deg{<:Real}
    θ, φ = wrap_spherical_angles_normalized(θ::T, φ::T, ::Type{<:Union{AzOverEl, ElOverAz}}) where T <: Deg{<:Real}

Function that takes as input two angles representing two orthogonal angular components of spherical coordinates (e.g. θ/φ, el/az, etc.) and returns two angles normalized to a consistent wrapping identifying the full sphere:
- `θ/φ` angles are wrapped such that `θ ∈ [0°, 180°]` and `φ ∈ [-180°, 180°]`
- `el/az` angles are wrapped such that `el ∈ [-90°, 90°]` and `az ∈ [-180°, 180°]`

!!! note
    This function already assumes that the provided input angles are already normalized such that both are in the [-180°, 180°] range. If you want to normalize the inputs automatically use the `wrap_first_angle` function.
"""
wrap_spherical_angles_normalized(az::T, el::T, ::Type{<:Union{AzOverEl, ElOverAz, AzEl, AER}}) where {T <: Deg{<:Real}} =
    ifelse(
        abs(el) <= 90°,  # Condition
        (az, el), # Azimuth angle is already between -180° and 180° as it's already been normalized
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
wrap_spherical_angles(α::ValidAngle, β::ValidAngle, ::Type{T}) where T <: Union{ThetaPhi, AzOverEl, ElOverAz, AER} = wrap_spherical_angles_normalized(to_degrees(α, RoundNearest), to_degrees(β, RoundNearest), T)
wrap_spherical_angles(p::Point2D, ::Type{T}) where T <: Union{ThetaPhi, AzOverEl, ElOverAz, AER} = wrap_spherical_angles(p[1], p[2], T)

##### TO MOVE

const WithNumbertype{T} = Union{AbstractSatcomCoordinate{T}, AbstractCRSTransform{T}}
