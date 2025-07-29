module SatcomCoordinates

using BasicTypes: BasicTypes, constructor_without_checks, to_degrees, to_meters, Met, Deg, Rad, UnitfulAngleQuantity, ValidAngle, Point2D, Point3D, Point, PS, ValidDistance, to_radians, asdeg, stripdeg, Length, enforce_unit, enforce_unitless, valuetype, change_valuetype, common_valuetype, promote_valuetype, getproperty_oftype, basetype, bypass_bottom
using ConstructionBase: ConstructionBase, getproperties, getfields, constructorof
using StaticArrays: StaticArrays, FieldVector, SVector, @SVector, SA, StaticMatrix, StaticVector
using LinearAlgebra: LinearAlgebra, normalize, norm
using PlutoShowHelpers: PlutoShowHelpers, DefaultShowOverload, HideWhenCompact, DualDisplayAngle, DisplayLength, InsidePluto, OutsidePluto, HideWhenFull, Ellipsis, repl_summary, shortname, longname, show_namedtuple
using Random: Random, SamplerType, AbstractRNG
using Rotations: Rotations, Rotation, nearest_rotation, RotMatrix, RotMatrix3
using TransformsBase: TransformsBase, Transform, Identity, isinvertible, isrevertible, inverse, apply, →
using Unitful: Unitful, Quantity, ustrip, rad, @u_str, °, km, Units, NoUnits

# To move to extension
using SatelliteToolboxTransformations: SatelliteToolboxTransformations, ecef_to_geodetic, geodetic_to_ecef
using SatelliteToolboxBase: SatelliteToolboxBase, Ellipsoid

# From deps
export °, km, @u_str # From Unitful
export to_degrees, to_meters # From BasicTypes
export Identity # From TransformsBase

include("define_properties.jl")
public @define_properties

include("types/abstract_types.jl")
export AbstractCRS, AbstractPointingCRS, AbstractSphericalCRS, AbstractSatcomCoordinate, AbstractCRSTransform

include("transforms.jl")
export RawAffineTransform, RawTranslation, RawRotation

include("coordinates.jl")
export Pointing, Coordinate, change_crs

include("raw.jl")
export Raw

# include("types/traits.jl")

export PointingCRS

include("pointing.jl")
export UV, ThetaPhi, AzEl, AzOverEl, ElOverAz, DirectionCosines

include("cartesian.jl")
export Cartesian

include("spherical.jl")
export SphericalCRS

include("ecef.jl")
export ECEF

include("lla.jl")
export LLA

include("topocentric.jl")
export NED

include("helpers.jl")
export iscartesiancrs, cartesiancrs, pointingcrs, default_wrappedcrs, rootcrs

include("deps_interface.jl")


# include("types/pointing_offsets.jl") 
# public PointingOffset

# include("types/geocentric.jl") 
# export ECEF, ECI, LLA 

# include("types/topocentric.jl") 
# export ENU, NED, AER 

# include("types/local.jl") 
# export LocalCartesian, GeneralizedSpherical 

# include("types/transforms.jl") 
# export CRSRotation, BasicCRSTransform, InverseTransform 

# include("types/type_aliases.jl") 
# export Spherical, AzElDistance

# include("functions/traits.jl")

# include("functions/pointing.jl")
# include("functions/pointing_offsets.jl")
# export get_angular_distance, get_angular_offset, add_angular_offset

# include("functions/geocentric.jl")
# include("functions/topocentric.jl")
# include("functions/local.jl")
# include("functions/transforms.jl")
# public origin, rotation

# include("functions/fieldvalues.jl")

# include("utils.jl")
# export numbertype, enforce_numbertype, has_numbertype, change_numbertype, default_numbertype, raw_properties, raw_svector, raw_properties

# include("functions/fallbacks.jl")

end # module SatComCoordinates