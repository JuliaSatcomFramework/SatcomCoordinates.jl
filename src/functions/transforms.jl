##### Constructors #####
# Rotation
# Orthonormalize non-RotMatrix inputs
CRSRotation(R::StaticMatrix{3, 3}) = CRSRotation(nearest_rotation(R))

# Basic transform
function BasicCRSTransform(rotation::StaticMatrix{3, 3}, origin::AbstractPosition) 
    position_trait(origin) isa CartesianPositionTrait || throw(ArgumentError("`origin` must be a position in Cartesian coordinates"))
    BasicCRSTransform(CRSRotation(rotation), origin)
end


##### Our Interface #####
"""
    origin(t::AbstractAffineCRSTransform)

This function should return an object which is subtype of `CartesianPosition` and represents the origin of the starting CRS in the target CRS.
"""
origin(t::AbstractAffineCRSTransform) = t.origin
origin(t::InverseTransform) = origin(t.transform)

"""
    rotation(t::AbstractAffineCRSTransform)

This function should return a `CRSRotation` object representing the rotation to align the starting CRS to the target CRS.
"""
rotation(t::CRSRotation) = return t
rotation(t::AbstractCRSRotation) = return t.rotation
rotation(t::AbstractAffineCRSTransform) = return t.rotation
rotation(t::InverseTransform) = rotation(t.transform) |> inverse
rotation(t::Identity) = return t

##### Base.getproperty #####
function Base.getproperty(i::InverseTransform, s::Symbol)
    t = getfield(i, :transform)
    s == :transform && return t
    return getproperty(t, s)
end

##### TransformsBase interface #####
# Generic
TransformsBase.isrevertible(t::AbstractCRSTransform) = 
isinvertible(t)
TransformsBase.isinvertible(t::AbstractCRSTransform) = return true
TransformsBase.inverse(t::AbstractCRSTransform) = InverseTransform(t)
TransformsBase.inverse(t::InverseTransform) = t.transform

TransformsBase.parameters(t::AbstractCRSTransform) = getfields(t)

# Fallback apply, actual methods should be defined taking StaticVector as reference input if not for special cases
function TransformsBase.apply(t::AbstractCRSTransform, coords::LocalCartesian) 
    new_coords, _ = apply(t, raw_svector(coords))
    return LocalCartesian(new_coords), nothing
end

# Rotation
# We are assuming that the input matrix is already orthonormalized
TransformsBase.inverse(t::CRSRotation) = CRSRotation(inv(t.rotation))


TransformsBase.apply(t::CRSRotation, coords::StaticVector) =
    return t.rotation * coords, nothing

TransformsBase.apply(t::AbstractCRSRotation, coords::StaticVector) =
    return apply(rotation(t), coords)

# Affine transform
function TransformsBase.apply(t::AbstractAffineCRSTransform, coords::StaticVector)
    rotated, _ = apply(rotation(t), coords)
    new_coords = rotated + raw_svector(origin(t))
    return new_coords, nothing
end

function TransformsBase.apply(t::InverseTransform{<:Any, <:AbstractAffineCRSTransform}, coords::StaticVector)
    shifted = coords - raw_svector(origin(t))
    rotated, _ = apply(rotation(t), shifted)
    return rotated, nothing
end
TransformsBase.apply(t::InverseTransform{<:Any, <:AbstractCRSRotation}, coords::StaticVector) = return apply(rotation(t), coords)

#### Transformations ####
TransformsBase.:(→)(r1::CRSRotation, r2::CRSRotation) = CRSRotation(r2.rotation * r1.rotation)

##### Random.rand #####
function Random.rand(rng::AbstractRNG, ::SamplerType{C}) where C <: CRSRotation
    T = numbertype(enforce_numbertype(C))
    R = rand(rng, RotMatrix3{T})
    return CRSRotation(R)
end

function Random.rand(rng::AbstractRNG, ::SamplerType{A}) where A <: BasicCRSTransform
    T = numbertype(enforce_numbertype(A))
    R = rand(rng, CRSRotation{T})
    origin = rand(rng, LocalCartesian{T})
    return BasicCRSTransform(R, origin)
end


##### Base.convert #####
Base.convert(::Type{CRSRotation}, t::TR) where TR <: CRSRotation = return t
Base.convert(::Type{CRSRotation{T}}, t::CRSRotation{T}) where {T <: AbstractFloat} = return t
Base.convert(::Type{CRSRotation{T}}, t::CRSRotation) where {T <: AbstractFloat} = return CRSRotation(change_numbertype(T, t.rotation))

Base.convert(::Type{BasicCRSTransform}, t::TR) where TR <: BasicCRSTransform = return t
Base.convert(::Type{BasicCRSTransform{T}}, t::BasicCRSTransform{T}) where {T <: AbstractFloat} = return t
Base.convert(::Type{BasicCRSTransform{T}}, t::BasicCRSTransform) where {T <: AbstractFloat} = BasicCRSTransform(change_numbertype(T, t.rotation), change_numbertype(T, t.origin))

Base.convert(::Type{InverseTransform}, t::TR) where TR <: InverseTransform = return t
Base.convert(::Type{InverseTransform{T}}, t::InverseTransform{T}) where {T <: AbstractFloat} = return t
Base.convert(::Type{InverseTransform{T}}, t::InverseTransform) where {T <: AbstractFloat} = InverseTransform(change_numbertype(T, t.transform))

##### isnan #####
Base.isnan(t::CRSRotation) = return any(isnan, t.rotation)
Base.isnan(t::AbstractCRSRotation) = return isnan(t |> rotation)
Base.isnan(t::AbstractAffineCRSTransform) = return isnan(t |> rotation) || isnan(t |> origin)
Base.isnan(it::InverseTransform) = return isnan(it.transform)

#### Custom show overloads ####
PlutoShowHelpers.repl_summary(t::AbstractCRSTransform) = shortname(t) * " Transform"