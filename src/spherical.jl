##################################################################
########                 Type Definitions                 ########
##################################################################
"""
    SphericalCRS{CRS <: AbstractPointingCRS} <: AbstractCRS

A generic spherical CRS, which wraps a pointing CRS 
"""
struct SphericalCRS{CRS <: AbstractCRS, PT <: AbstractPointingCRS{CRS}} <: AbstractCRS 
    cartesian::CRS
    pointing::PT
    function SphericalCRS(pointing_crs::AbstractPointingCRS) 
        pointing_crs isa DirectionCosines && throw(ArgumentError("The `DirectionCosines` CRS is not a supported PointingCRS for the `SphericalCRS` type"))
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