"""
    RawAffineTransform{R, T} <: Transform

A transform that is defined by a rotation and a translation that is intended to operate on SVectors or NTuples of size `N`

# Arguments
- `rotation::Union{Identity, RotMatrix{N, P}}`: The rotation of the transform.
- `translation::Union{Identity, NTuple{N, P}, SVector{N, P}}`: The translation of the transform.

"""
struct RawAffineTransform{R, T} <: AbstractRawCRSTransform
    rotation::R
    translation::T
    function RawAffineTransform(rotation::Union{Identity, Rotation{N, <:Real}}, translation::Union{Identity, Point{N, <:Real}}) where {N}
        rotation isa Identity && translation isa Identity && return Identity()
        F = common_valuetype(AbstractFloat, Float64, rotation, translation)
        if !(rotation isa Identity)
            rotation = RotMatrix{N, F}(rotation)
        end
        if !(translation isa Identity)
            translation = SVector{N, F}(translation)
        end
        R = typeof(rotation)
        T = typeof(translation)
        return new{R, T}(rotation, translation)
    end
end

raw_rotation(t::RawAffineTransform) = t.rotation
raw_translation(t::RawAffineTransform) = t.translation

TransformsBase.parameters(t::T) where T <: RawAffineTransform = getproperties(t)

function BasicTypes.valuetype(::Type{RawAffineTransform{R, T}}) where {R, T}
    r = valuetype(R)
    return r === Union{} ? valuetype(T) : r
end

ncoords(::Type{<:RawAffineTransform{R, T}}) where {R, T} = R <: Identity ? ncoords(T) : ncoords(R)

const RawTranslation{T} = RawAffineTransform{Identity, T}
const RawRotation{R} = RawAffineTransform{R, Identity}

RawTranslation(translation) = RawAffineTransform(Identity(), translation)
RawRotation(rotation) = RawAffineTransform(rotation, Identity())

#

TransformsBase.isinvertible(::Type{<:RawAffineTransform}) = return true
TransformsBase.isrevertible(::Type{<:RawAffineTransform}) = return true

function TransformsBase.apply(t::RawAffineTransform, v::NTuple{N, <:AbstractFloat}) where {N}
    N === ncoords(t) || throw(DimensionMismatch("The dimension of the input vector ($(N)) does not match the dimension of the transform ($(ncoords(t)))"))
    T = valuetype(t)
    v = SVector(map(T, v))
    trans = raw_translation(t)
    rot = raw_rotation(t)
    newv = if trans isa Identity
        rot * v
    elseif rot isa Identity
        trans + v
    else
        rot * v + trans
    end
    return Tuple(map(T, newv)), nothing
end

function TransformsBase.inverse(t::RawAffineTransform) 
    rot = raw_rotation(t)
    trans = raw_translation(t)
    if rot isa Identity
        return RawTranslation(-trans)
    elseif trans isa Identity
        return RawRotation(inv(rot))
    else
        rinv = inv(rot)
        return RawAffineTransform(rinv, -rinv * trans)
    end
end

##### Random generation #####
Random.rand(rng::AbstractRNG, ::Random.SamplerType{RawAffineTransform}) = return RawAffineTransform(rand(rng, RotMatrix3), rand(rng, SVector{3}))
Random.rand(rng::AbstractRNG, ::Random.SamplerType{RawTranslation}) = return RawAffineTransform(Identity(), rand(rng, SVector{3}))
Random.rand(rng::AbstractRNG, ::Random.SamplerType{RawRotation}) = return RawAffineTransform(rand(rng, RotMatrix3), Identity())
