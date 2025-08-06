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

TransformsBase.isinvertible(::Type{<:CRSTransform{<:Any, <:Any, T}}) where T = return isinvertible(T)
TransformsBase.isrevertible(::Type{<:CRSTransform{<:Any, <:Any, T}}) where T = return isrevertible(T)

TransformsBase.parameters(t::T) where T <: CRSTransform = getproperties(t)

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