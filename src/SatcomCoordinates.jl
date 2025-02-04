module SatcomCoordinates

using BasicTypes: BasicTypes, constructor_without_checks, to_degrees, to_meters, Met, Deg, Rad, UnitfulAngleQuantity, ValidAngle, Point2D, Point3D, Point, PS, ValidDistance, to_radians, basetype, asdeg, stripdeg
using ConstructionBase: ConstructionBase, getfields
using StaticArrays: StaticArrays, FieldVector, SVector, @SVector, SA, StaticMatrix, StaticVector
using LinearAlgebra: LinearAlgebra, normalize, norm
using Random: Random, SamplerType, AbstractRNG
using Rotations: Rotations, Rotation, nearest_rotation, RotMatrix3
using TransformsBase: TransformsBase, Transform, Identity, isinvertible, isrevertible, inverse, apply
using Unitful: Unitful, Quantity, ustrip, rad, @u_str, °

# From deps
export °, @u_str # From Unitful
export to_degrees, to_meters # From BasicTypes
export Identity # From TransformsBase

include("types/abstract_types.jl")
export AbstractSatcomCoordinate, CartesianPosition, LengthCartesian, AngularPointing, AbstractPointing, AbstractCRSTransform
public AbstractPointingOffset

include("types/pointing.jl")
export PointingVersor, UV, ThetaPhi, AzEl, AzOverEl, ElOverAz

include("types/pointing_offsets.jl")
public UVOffset, ThetaPhiOffset

include("types/geocentric.jl")
export ECEF, ECI, LLA

include("types/topocentric.jl")
export ENU, NED, AER

include("types/local.jl")
export LocalCartesian, GeneralizedSpherical

include("types/transforms.jl")
export CRSRotation, BasicCRSTransform, InverseTransform

include("types/type_aliases.jl")
export GeocentricPosition, TopocentricPosition, GenericLocalPosition, Spherical, AzElDistance

include("functions/pointing.jl")
include("functions/pointing_offsets.jl")
export get_angular_distance, get_angular_offset, add_angular_offset

include("functions/geocentric.jl")
include("functions/topocentric.jl")
include("functions/local.jl")
include("functions/transforms.jl")
public origin, rotation

include("functions/fallbacks.jl")

include("utils.jl")
export numbertype, enforce_numbertype, has_numbertype, change_numbertype

end # module SatComCoordinates