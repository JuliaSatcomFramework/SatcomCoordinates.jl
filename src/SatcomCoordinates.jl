module SatcomCoordinates

using BasicTypes: BasicTypes, constructor_without_checks, to_degrees, to_meters, Met, Deg, Rad, UnitfulAngleQuantity, ValidAngle, Point2D, Point3D, Point, PS, ValidDistance, to_radians, asdeg, stripdeg, Length, enforce_unit, enforce_unitless, valuetype, change_valuetype, common_valuetype, promote_valuetype, getproperty_oftype, basetype, bypass_bottom, Optional, NotProvided, @fallback, fieldname_oftype, FIELDNAME_NOT_FOUND_SYMBOL, NotFound
using ConstructionBase: ConstructionBase, getproperties, getfields, constructorof
using StaticArrays: StaticArrays, FieldVector, SVector, @SVector, SA, StaticMatrix, StaticVector
using LinearAlgebra: LinearAlgebra, normalize, norm
using PlutoShowHelpers: PlutoShowHelpers, DefaultShowOverload, HideWhenCompact, DualDisplayAngle, DisplayLength, InsidePluto, OutsidePluto, HideWhenFull, Ellipsis, repl_summary, shortname, longname, show_namedtuple
using Random: Random, SamplerType, AbstractRNG
using Rotations: Rotations, Rotation, nearest_rotation, RotMatrix, RotMatrix3
using TransformsBase: TransformsBase, Transform, Identity, isinvertible, isrevertible, inverse, apply
using Unitful: Unitful, Quantity, ustrip, rad, @u_str, °, km, Units, NoUnits

# From deps
export °, km, @u_str # From Unitful
export Identity # From TransformsBase

include("define_properties.jl")
public @define_properties

include("abstract_types.jl")
export AbstractCRS, AbstractPointingCRS, AbstractSatcomCoordinate, AbstractCRSTransform, AbstractLinkedCRS

include("traits.jl")
export hascrstrait, traitcrs, rootcrs, linkedcrs, cartesiancrs

include("coordinates.jl")
export Pointing, Coordinate, change_crs

include("transforms/rawaffine.jl")
export RawAffineTransform, RawRotation, RawTranslation

include("transforms/rawcomposed.jl")

include("transforms/crstransform.jl")
export CRSTransform

include("transforms/compose.jl")
export compose

include("transforms/traits.jl")
export isaffinetransform, israwtransform

include("raw.jl")
export Raw

include("pointing/types.jl")
export UV, ThetaPhi, AzEl, AzOverEl, ElOverAz, DirectionCosines

include("pointing/constructors.jl")

include("pointing/transforms.jl")

include("pointing/misc.jl")

include("pointing/traits.jl")
export pointingcrs

include("cartesian.jl")
export Cartesian, AffineCartesian

include("spherical.jl")
export SphericalCRS

include("geocentric/basics.jl")
export frameid, ellipsoidparams, EarthDefault

include("geocentric/ecef.jl")
export ECEF

include("geocentric/eci.jl")
export ECI

include("geocentric/lla.jl")
export LLA

include("geocentric/transforms.jl")

include("geocentric/traits.jl")
export ecefcrs, ecicrs, llacrs

include("topocentric.jl")
export NED, ENU, AER, ecef_origin, lla_origin, topocrs

include("helpers.jl")
export change_crs

include("getters.jl")
export getcrs, getcrstype, getcrstransform_raw, getcrstransform

include("deps_interface.jl")


end # module SatComCoordinates