##### Constructors #####
# Rotation
# Orthonormalize non-RotMatrix inputs
CRSRotation(R::StaticMatrix{3, 3}) = CRSRotation(nearest_rotation(R))

# Basic transform
BasicCRSTransform(rotation::StaticMatrix{3, 3}, origin::CartesianPosition) = BasicCRSTransform(CRSRotation(rotation), origin)


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
rotation(t::AbstractAffineCRSTransform) = t.rotation
rotation(t::InverseTransform) = rotation(t.transform) |> inverse
rotation(t::Identity) = return t

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
    new_coords, _ = apply(t, to_svector(coords))
    return LocalCartesian(new_coords), nothing
end

# Rotation
# We are assuming that the input matrix is already orthonormalized
TransformsBase.inverse(t::CRSRotation) = CRSRotation(inv(t.rotation))

function TransformsBase.apply(t::CRSRotation, coords::StaticVector)
    return t.rotation * coords, nothing
end

# Affine transform
function TransformsBase.apply(t::AbstractAffineCRSTransform, coords::StaticVector)
    rotated, _ = apply(rotation(t), coords)
    new_coords = rotated + to_svector(origin(t))
    return new_coords, nothing
end

function TransformsBase.apply(t::InverseTransform{<:Any, <:AbstractAffineCRSTransform}, coords::StaticVector)
    shifted = coords - to_svector(origin(t))
    rotated, _ = apply(rotation(t), shifted)
    return rotated, nothing
end

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
