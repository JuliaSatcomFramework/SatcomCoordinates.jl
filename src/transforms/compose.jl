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
    isaffinetransform(t1) && isaffinetransform(t2) || return RawComposedTransform(t1, t2)
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

# Composition
function _compose(t1::RawComposedTransform, t2::Transform)
    isaffinetransform(t1.t2) && isaffinetransform(t2) || throw(ArgumentError("The `_compose(t1::RawComposedTransform, t2::Transform)` method only works if both `t1.t2` and `t2` are affine transforms."))
    newt2 = _compose(t1.t2, t2)
    return RawComposedTransform(t1.t1, newt2)
end
function _compose(t1::Transform, t2::RawComposedTransform)
    isaffinetransform(t1) && isaffinetransform(t2.t1) || throw(ArgumentError("The `_compose(t1::Transform, t2::RawComposedTransform)` method only works if both `t1` and `t2.t1` are affine transforms."))
    newt1 = _compose(t1, t2.t1)
    return RawComposedTransform(newt1, t2.t2)
end
