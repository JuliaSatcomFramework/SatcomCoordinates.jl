struct InverseTransform{CRSₒ <: AbstractCRS, CRSᵢ <: AbstractCRS, F <: AbstractCRSTransform{CRSᵢ, CRSₒ}} <: AbstractCRSTransform{CRSₒ, CRSᵢ}
    transform::F
    InverseTransform(transform::F) where {CRSₒ <: AbstractCRS, CRSᵢ <: AbstractCRS, F <: AbstractCRSTransform{CRSᵢ, CRSₒ}} = new{CRSₒ, CRSᵢ, F}(transform)
end

struct CRSRotation{CRSₒ <: AbstractCRS, CRSᵢ <: AbstractCRS, T} <: AbstractAffineCRSTransform{CRSₒ, CRSᵢ, T}
    crsₒ::CRSₒ
    crsᵢ::CRSᵢ
    rotation::RotMatrix3{T}
end