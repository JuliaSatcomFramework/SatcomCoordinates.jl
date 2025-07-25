##################################################################
########                 Type Definitions                 ########
##################################################################
"""
    SphericalCRS{CRS <: AbstractPointingCRS} <: AbstractCRS

A generic spherical CRS, which wraps a pointing CRS 
"""
struct SphericalCRS{CRS <: AbstractPointingCRS} <: AbstractCRS 
    wrapped_crs::CRS
end
function (CRS::Type{<:SphericalCRS})()
    # This is the no-arg constructor, it creates a pointing CRS with the default wrapped CRS
    return CRS(default_wrappedcrs(CRS))
end
for T in (Vararg{Number, 3}, Point{3, Number})
    @eval function (CRS::Type{<:SphericalCRS})(coords::$T)
        # This is the constructor with coordinates, it creates a pointing CRS with the default wrapped CRS and the provided coordinates
        return CRS(default_wrappedcrs(CRS), coords...)
    end

    @eval function (CRS::Type{<:SphericalCRS})(wrapped_crs::AbstractPointingCRS, coords::$T)
        crs = CRS(wrapped_crs)
        return Position(crs, coords)
    end
end

##################################################################
########                 CRS Properties                  #########
##################################################################


@define_properties SphericalCRS [
    pointingcrs(_)... # This is a special synthax for the macro, saying that it should put here all the properties of the the `CRS` obtained by calling `pointingcrs(CRS::Type{<:SphericalCRS})`
    r => u"m" => (:distance, :range) # r as primary property name, u"m" as unit for `r` and `distance` and `range` as aliases for this property
]

pointingcrs(::Type{SphericalCRS{P}}) where P <: AbstractPointingCRS = P

default_wrappedcrs(::Type{<:SphericalCRS{P}}) where P <: AbstractPointingCRS = P()
default_wrappedcrs(::Type{<:SphericalCRS{<:Any}}) = ThetaPhi()