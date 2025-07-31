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

TransformsBase.isinvertible(::Type{<:RawAffineTransform}) = true
TransformsBase.isrevertible(::Type{<:RawAffineTransform}) = true

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

"""
    compose(t1, t2, ts...)

Compose the transforms `t1`, `t2`, `ts...` as if they were applied in argument order (e.g. first `t1` then `t2` then `ts...`).
"""
compose(t1::Transform, ts::Transform...) = foldl(_compose, ts; init = t1)

_compose(::Identity, t::Transform) = t
_compose(t::Transform, ::Identity) = t
_compose(::Identity, ::Identity) = Identity()

function _compose(t1::Transform, t2::Transform)
    israwtransform(t1) && israwtransform(t2) || throw(ArgumentError("The generic `_compose` method only works for raw transforms.\nYou need to implement a custom method for `SatcomCoordinates._compose` to support the composition of the provided transforms $(typeof(t1)) and $(typeof(t2))."))
    isaffinetransform(t1) && isaffinetransform(t2) || return ComposedRawTransform(t1, t2)
    t1rot = raw_rotation(t1)
    t1trans = raw_translation(t1)
    t2rot = raw_rotation(t2)
    t2trans = raw_translation(t2)
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

#### ComposedRawTransform ####
"""
    ComposedRawTransform{T1 <: Transform, T2 <: Transform} <: AbstractRawCRSTransform

A transform that is the composition of two raw transforms.

This type is automatically created when composing two raw (but non Identity) transforms that are not both affine (i.e. that do not satisfy `isaffinetransform(t) == true`).

This is for example the case when composing an affine transform with a transformation between LLA and ECEF or between Spherical and Cartesian coordinates.

# Fields
- `t1::T1`: The first transform.
- `t2::T2`: The second transform.

When applied to an object, the operation order is `t2(t1(obj))`
"""
struct ComposedRawTransform{T1 <: Transform, T2 <: Transform} <: AbstractRawCRSTransform
    t1::T1
    t2::T2
    function ComposedRawTransform(t1::Transform, t2::Transform) 
        israwtransform(t1) && israwtransform(t2) || throw(ArgumentError("Both transforms used to construct an object of type `ComposedRawTransform` must be **raw** (i.e. that satisfy `israwtransform(t) == true`)."))
        return new{typeof(t1), typeof(t2)}(t1, t2)
    end
end

TransformsBase.parameters(t::ComposedRawTransform) = (t.t1, t.t2)
function TransformsBase.isinvertible(::Type{<:ComposedRawTransform{T1, T2}}) where {T1, T2} 
    return isinvertible(T1) && isinvertible(T2)
end
function TransformsBase.isrevertible(::Type{<:ComposedRawTransform{T1, T2}}) where {T1, T2} 
    return isrevertible(T1) && isrevertible(T2)
end

function TransformsBase.apply(t::ComposedRawTransform, v::NTuple{<:Any, <:AbstractFloat})  
    newval = t.t2(t.t1(v))
    return newval, nothing
end

function TransformsBase.inverse(t::ComposedRawTransform) 
    it1 = inverse(t.t1)
    it2 = inverse(t.t2)
    return ComposedRawTransform(it2, it1)
end

# Composition
function _compose(t1::ComposedRawTransform, t2::Transform)
    isaffinetransform(t1.t2) && isaffinetransform(t2) || throw(ArgumentError("The `_compose(t1::ComposedRawTransform, t2::Transform)` method only works if both `t1.t2` and `t2` are affine transforms."))
    newt2 = _compose(t1.t2, t2)
    return ComposedRawTransform(t1.t1, newt2)
end
function _compose(t1::Transform, t2::ComposedRawTransform)
    isaffinetransform(t1) && isaffinetransform(t2.t1) || throw(ArgumentError("The `_compose(t1::Transform, t2::ComposedRawTransform)` method only works if both `t1` and `t2.t1` are affine transforms."))
    newt1 = _compose(t1, t2.t1)
    return ComposedRawTransform(newt1, t2.t2)
end

#### CRSTransform ####
struct CRSTransform{CRSₒ <: AbstractCRS, CRSᵢ <: AbstractCRS, T <: Transform} <: AbstractCRSTransform{CRSₒ, CRSᵢ}
    crsₒ::CRSₒ
    crsᵢ::CRSᵢ
    raw::T
    function CRSTransform(crsₒ::AbstractCRS, crsᵢ::AbstractCRS, raw::Transform)
        israwtransform(raw) || throw(ArgumentError("The input transform used to construct an object of type `CRSTransform` must be raw, which is not the case for the provided transform $(typeof(raw))."))
        ncoords(crsₒ) == ncoords_out(raw) || throw(DimensionMismatch("The dimension of the output CRS ($(ncoords(crsₒ))) does not match the output dimension of the raw transform ($(ncoords_out(raw)))."))
        ncoords(crsᵢ) == ncoords_in(raw) || throw(DimensionMismatch("The dimension of the input CRS ($(ncoords(crsᵢ))) does not match the input dimension of the raw transform ($(ncoords_in(raw)))."))
        return new{typeof(crsₒ), typeof(crsᵢ), typeof(raw)}(crsₒ, crsᵢ, raw)
    end
end

input_crs(t::CRSTransform) = t.crsᵢ
output_crs(t::CRSTransform) = t.crsₒ
raw_transform(t::CRSTransform) = t.raw

TransformsBase.isinvertible(::Type{<:CRSTransform{<:Any, <:Any, T}}) where T = TransformsBase.isinvertible(T)
TransformsBase.isrevertible(::Type{<:CRSTransform{<:Any, <:Any, T}}) where T = TransformsBase.isrevertible(T)

TransformsBase.parameters(t::AbstractCRSTransform) = getproperties(t)

function TransformsBase.apply(t::CRSTransform{<:Any, CRSᵢ}, c::Coordinate{CRSᵢ}) where {CRSᵢ}
    is_same_crs(crs(c), input_crs(t)) || throw(ArgumentError("The CRS of the provided coordinate ($(crs(c))) does not match the input CRS of the transform ($(input_crs(t)))."))
    raw = raw_transform(t)
    # Apply the transformation at the raw level
    tup = raw(tuplecoords(c))
    # We now construct the output coordinate without additional checks
    return constructor_without_checks(Coordinate, output_crs(t), tup), nothing
end

function TransformsBase.inverse(t::CRSTransform)
    raw = raw_transform(t)
    return CRSTransform(input_crs(t), output_crs(t), inverse(raw))
end