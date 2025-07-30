##################################################################
########                 Type Definitions                 ########
##################################################################
"""
    SphericalCRS{CRS <: AbstractPointingCRS} <: AbstractCRS

A generic spherical CRS, which wraps a pointing CRS 
"""
struct SphericalCRS{CRS <: AbstractCRS, PT <: Abstract2DPointingCRS{CRS}} <: AbstractCRS 
    cartesian::CRS
    pointing::PT
    function SphericalCRS(pointing_crs::Abstract2DPointingCRS) 
        cartesian_crs = cartesiancrs(pointing_crs)
        new{typeof(cartesian_crs), typeof(pointing_crs)}(cartesian_crs, pointing_crs)
    end
end
function (CRS::Type{<:SphericalCRS})()
    # This is the no-arg constructor, it creates a pointing CRS with the default wrapped CRS
    return SphericalCRS(default_wrappedcrs(CRS))
end

##################################################################
########                 CRS Properties                  #########
##################################################################


@define_properties SphericalCRS [
    pointingcrs(_)... # This is a special synthax for the macro, saying that it should put here all the properties of the the `CRS` obtained by calling `pointingcrs(CRS::Type{<:SphericalCRS})`
    r => u"m" => (:distance, :range) # r as primary property name, u"m" as unit for `r` and `distance` and `range` as aliases for this property
]
ncoords(::Type{SphericalCRS}) = 3 # This is needed to avoid errors in the simplified coordinate constructor when not specifying the CRS

pointingcrs(::Type{<:SphericalCRS{<:Any, P}}) where P <: AbstractPointingCRS = P
pointingcrs(s::SphericalCRS) = s.pointing

default_wrappedcrs(::Type{<:SphericalCRS{<:Any, P}}) where P <: AbstractPointingCRS = P()
default_wrappedcrs(::Type{<:SphericalCRS{C}}) where C = ThetaPhi(C())
default_wrappedcrs(::Type{SphericalCRS}) = ThetaPhi()

#### Random.rand #####
function rand_tuplecoords(rng::AbstractRNG, crs::SphericalCRS, T::Type{<:AbstractFloat})
    pt = rand_tuplecoords(rng, pointingcrs(crs), T)
    r = rand(rng, T)
    return (pt..., r)
end

#### Conversion ####
abstract type SphericalTransform <: AbstractCRSTransform end

TransformsBase.isinvertible(::SphericalTransform) = true
TransformsBase.isrevertible(::SphericalTransform) = true

ncoords(::Type{<:SphericalTransform}) = 3

struct SphericalToCartesian{PT <: Abstract2DPointingCRS} <: SphericalTransform end
struct CartesianToSpherical{PT <: Abstract2DPointingCRS} <: SphericalTransform end

TransformsBase.inverse(::SphericalToCartesian{PT}) where PT <: Abstract2DPointingCRS = CartesianToSpherical{PT}()
TransformsBase.inverse(::CartesianToSpherical{PT}) where PT <: Abstract2DPointingCRS = SphericalToCartesian{PT}()

function TransformsBase.apply(::SphericalToCartesian{PT}, tup::NTuple{3, <:AbstractFloat}) where PT <: Abstract2DPointingCRS
    dctup = AngularPointingToDirectionCosines{PT}()(tup[1:2])
    return dctup .* tup[3], nothing
end
function TransformsBase.apply(::CartesianToSpherical{PT}, tup::NTuple{3, <:AbstractFloat}) where PT <: Abstract2DPointingCRS
    r = hypot(tup...)
    pt = DirectionCosinesToAngularPointing{PT}()(tup ./ r)
    return (pt..., r), nothing
end

function raw_linkedcrs_transform(::SphericalCRS{<:Any, PT}) where {PT <: Abstract2DPointingCRS}
    return SphericalToCartesian{PT}()
end

function transform_tuplecoords(sph::SphericalCRS{CRS}, ::CRS, tup::NTuple{3, <:AbstractFloat}) where CRS <: AbstractCRS
    t = raw_linkedcrs_transform(sph)
    return inverse(t)(tup)
end
function transform_tuplecoords(::CRS, sph::SphericalCRS{CRS}, tup::NTuple{3, <:AbstractFloat}) where CRS <: AbstractCRS
    t = raw_linkedcrs_transform(sph)
    return t(tup)
end