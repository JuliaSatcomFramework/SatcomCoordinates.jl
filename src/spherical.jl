##################################################################
########                 Type Definitions                 ########
##################################################################
"""
    SphericalCRS{CRS <: AbstractPointingCRS, PT <: Abstract2DPointingCRS{CRS}} <: AbstractLinkedCRS{CRS}

A generic spherical CRS, which wraps a Cartesian CRS as root and has properties that are specified based on the pointing CRS PT

# Constructor
    SphericalCRS(pointing_crs::Abstract2DPointingCRS)

The only constructor expects directly a 2D pointing CRS as input and will automatically extracts its base Cartesian CRS.

# Example
```julia
# Generate a Spherical CRS based on ThetaPhi over a plain Cartesian CRS
SphericalCRS() # This is equivalent to SphericalCRS(ThetaPhi())

# Generate one where the pointing direction is `AzEl`
SphericalCRS(AzEl())

# Make the so-called `AER` CRS which is AzEl over an ENU frame
aer_crs = SphericalCRS(AzEl(ENU(LLA(0,0,1200km))))
```
"""
struct SphericalCRS{CRS <: AbstractCRS, PT <: Abstract2DPointingCRS{CRS}} <: AbstractLinkedCRS{CRS} 
    cartesian::CRS
    pointing::PT
    function SphericalCRS(pointing_crs::Abstract2DPointingCRS) 
        cartesian_crs = cartesiancrs(pointing_crs)
        new{typeof(cartesian_crs), typeof(pointing_crs)}(cartesian_crs, pointing_crs)
    end
end
SphericalCRS() = SphericalCRS(ThetaPhi())

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

#### Random.rand #####
function rand_tuplecoords(rng::AbstractRNG, crs::SphericalCRS, T::Type{<:AbstractFloat})
    pt = rand_tuplecoords(rng, pointingcrs(crs), T)
    r = rand(rng, T)
    return (pt..., r)
end

#### Conversion ####
abstract type SphericalTransform <: AbstractRawCRSTransform end

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

# These are methods to extract just pointing from Spherical
# This handles simply extracting the pointing
function transform_tuplecoords(crsₒ::PT, crsᵢ::SphericalCRS{CRS, PT}, tup::NTuple{3, <:AbstractFloat}) where {CRS <: AbstractCRS, PT <: Abstract2DPointingCRS{CRS}}
    is_same_crs(crsₒ, pointingcrs(crsᵢ)) || throw(ArgumentError("The provided pointing CRS ($(crsₒ)) does not match the pointing CRS of the provided Spherical CRS ($(pointingcrs(crsᵢ)))."))
    return tup[1:2]
end
# This handles different pointing CRS from the one stored in the Spherical
function transform_tuplecoords(crsₒ::AbstractPointingCRS{CRS}, crsᵢ::SphericalCRS{CRS}, tup::NTuple{3, <:AbstractFloat}) where CRS <: AbstractCRS
    is_same_crs(linkedcrs(crsₒ), linkedcrs(crsᵢ)) || throw(ArgumentError("The provided Pointing and Spherical CRSs are not derived from the same Cartesian CRS."))
    ptup = transform_tuplecoords(pointingcrs(crsᵢ), crsᵢ, tup)
    return transform_tuplecoords(crsₒ, pointingcrs(crsᵢ), ptup)
end
# This fast tracks just changing pointing without going back to the underlying cartesian
function transform_tuplecoords(crsₒ::SphericalCRS{CRS}, crsᵢ::SphericalCRS{CRS}, tup::NTuple{3, <:AbstractFloat}) where {CRS <: AbstractCRS}
    is_same_crs(crsₒ, crsᵢ) && return tup
    is_same_crs(linkedcrs(crsₒ), linkedcrs(crsᵢ)) || throw(ArgumentError("The provided Spherical CRSs are not derived from the same Cartesian CRS."))
    pt..., r = tup
    pt = transform_tuplecoords(pointingcrs(crsₒ), pointingcrs(crsᵢ), pt)
    return (pt..., r)
end

##### Base.show #####
function PlutoShowHelpers.repl_summary(c::SphericalCRS)
    string(
        PlutoShowHelpers.shortname(c), 
        "{",
        PlutoShowHelpers.shortname(linkedcrs(c)),
        ", ",
        PlutoShowHelpers.shortname(pointingcrs(c)),
        "}"
    )
end