#### RawComposedTransform ####
"""
    RawComposedTransform{T1 <: Transform, T2 <: Transform} <: AbstractRawCRSTransform

A transform that is the composition of two raw transforms.

This type is automatically created when composing two raw (but non Identity) transforms that are not both affine (i.e. that do not satisfy `isaffinetransform(t) == true`).

This is for example the case when composing an affine transform with a transformation between LLA and ECEF or between Spherical and Cartesian coordinates.

# Fields
- `t1::T1`: The first transform.
- `t2::T2`: The second transform.

When applied to an object, the operation order is `t2(t1(obj))`
"""
struct RawComposedTransform{T1 <: Transform, T2 <: Transform} <: AbstractRawCRSTransform
    t1::T1
    t2::T2
    function RawComposedTransform(t1::Transform, t2::Transform) 
        israwtransform(t1) && israwtransform(t2) || throw(ArgumentError("Both transforms used to construct an object of type `RawComposedTransform` must be **raw** (i.e. that satisfy `israwtransform(t) == true`)."))
        return new{typeof(t1), typeof(t2)}(t1, t2)
    end
end

TransformsBase.parameters(t::RawComposedTransform) = (t.t1, t.t2)
function TransformsBase.isinvertible(::Type{<:RawComposedTransform{T1, T2}}) where {T1, T2} 
    return isinvertible(T1) && isinvertible(T2)
end
function TransformsBase.isrevertible(::Type{<:RawComposedTransform{T1, T2}}) where {T1, T2} 
    return isrevertible(T1) && isrevertible(T2)
end

function TransformsBase.apply(t::RawComposedTransform, v::NTuple{<:Any, <:AbstractFloat})  
    newval = t.t2(t.t1(v))
    return newval, nothing
end

function TransformsBase.inverse(t::RawComposedTransform) 
    it1 = inverse(t.t1)
    it2 = inverse(t.t2)
    return RawComposedTransform(it2, it1)
end

ncoords_in(::Type{<:RawComposedTransform{T1, T2}}) where {T1, T2} = ncoords_in(T1)
ncoords_out(::Type{<:RawComposedTransform{T1, T2}}) where {T1, T2} = ncoords_out(T2)