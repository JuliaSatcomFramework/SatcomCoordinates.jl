"""
    RawAffineTransform{R, T} <: Transform

A transform that is defined by a rotation and a translation that is intended to operate on SVectors or NTuples of size `N`

# Arguments
- `rotation::Union{Identity, RotMatrix{N, P}}`: The rotation of the transform.
- `translation::Union{Identity, NTuple{N, P}, SVector{N, P}}`: The translation of the transform.

"""
struct RawAffineTransform{R, T} <: Transform
    rotation::R
    translation::T
    function RawAffineTransform(rotation::Union{Identity, Rotation{N, P}}, translation::Union{Identity, NTuple{N, P}, SVector{N, P}}) where {N, P <: AbstractFloat}
        rotation isa Identity && translation isa Identity && return Identity()
        if !(rotation isa Identity)
            rotation = RotMatrix(rotation)
        end
        if !(translation isa Identity)
            translation = SVector(translation)
        end
        R = typeof(rotation)
        T = typeof(translation)
        return new{R, T}(rotation, translation)
    end
end

TransformsBase.parameters(t::RawAffineTransform) = getproperties(t)

function BasicTypes.valuetype(::Type{RawAffineTransform{R, T}}) where {R, T}
    r = valuetype(R)
    return r === Union{} ? valuetype(T) : r
end

ncoords(::Type{<:Rotation{N}}) where {N} = N
ncoords(::Type{<:SVector{N}}) where {N} = N
ncoords(::Type{RawAffineTransform{R, T}}) where {R, T} = T <: Identity ? ncoords(R) : ncoords(T)
ncoords(t::RawAffineTransform) = ncoords(typeof(t))
ncoords(v::Union{SVector, NTuple}) = length(v)



const RawTranslation{T} = RawAffineTransform{Identity, T}
const RawRotation{R} = RawAffineTransform{R, Identity}

RawTranslation(translation) = RawAffineTransform(Identity(), translation)
RawRotation(rotation) = RawAffineTransform(rotation, Identity())

TransformsBase.isinvertible(::RawAffineTransform) = true
TransformsBase.isrevertible(::RawAffineTransform) = true

function TransformsBase.apply(t::RawAffineTransform, v::Union{SVector, NTuple})
    ncoords(v) === ncoords(t) || throw(DimensionMismatch("The dimension of the input vector ($(ncoords(v))) does not match the dimension of the transform ($(ncoords(t)))"))
    T = valuetype(t)
    v = SVector(map(T, v))
    trans = t.translation
    rot = t.rotation
    newv = if trans isa Identity
        rot * v
    elseif rot isa Identity
        trans + v
    else
        rot * v + trans
    end
    return Tuple(newv), nothing
end

function TransformsBase.inverse(t::RawAffineTransform) 
    rot = t.rotation
    trans = t.translation
    if rot isa Identity
        return RawTranslation(-trans)
    elseif trans isa Identity
        return RawRotation(inv(rot))
    else
        rinv = inv(rot)
        return RawAffineTransform(rinv, -rinv * trans)
    end
end

"""
    compose(t1, t2, ts...)

Compose the transforms `t1`, `t2`, `ts...` as if they were applied in argument order (e.g. first `t1` then `t2` then `ts...`).
"""
compose(t1::Transform, ts::Transform...) = foldl(_compose, ts; init = t1)

_compose(::Identity, t::Transform) = t
_compose(t::Transform, ::Identity) = t
_compose(::Identity, ::Identity) = Identity()

function _compose(t1::RawAffineTransform, t2::RawAffineTransform)
    t1rot = t1.rotation
    t1trans = t1.translation
    t2rot = t2.rotation
    t2trans = t2.translation
    rot = if t1rot isa Identity
        t2rot
    elseif t2rot isa Identity
        t1rot
    else
        t2rot * t1rot
    end
    trans = if t1trans isa Identity
        t2trans
    elseif t2rot isa Identity
        t1trans + t2trans
    elseif t2trans isa Identity
        t2rot * t1trans
    else
        t2rot * t1trans + t2trans
    end
    return RawAffineTransform(rot, trans)
end