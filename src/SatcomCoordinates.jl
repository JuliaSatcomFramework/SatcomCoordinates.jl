module SatcomCoordinates

using BasicTypes: BasicTypes, constructor_without_checks, to_degrees, to_meters, Met, Deg, Rad, UnitfulAngleQuantity, ValidAngle, Point2D, Point3D, Point, PS, ValidDistance, to_radians, basetype, asdeg, stripdeg, Length
using ConstructionBase: ConstructionBase, getproperties, getfields
using StaticArrays: StaticArrays, FieldVector, SVector, @SVector, SA, StaticMatrix, StaticVector
using LinearAlgebra: LinearAlgebra, normalize, norm
using PlutoShowHelpers: PlutoShowHelpers, DefaultShowOverload, HideWhenCompact, DualDisplayAngle, DisplayLength, InsidePluto, OutsidePluto, HideWhenFull, Ellipsis, repl_summary, shortname, longname, show_namedtuple
using Random: Random, SamplerType, AbstractRNG
using Rotations: Rotations, Rotation, nearest_rotation, RotMatrix3
using TransformsBase: TransformsBase, Transform, Identity, isinvertible, isrevertible, inverse, apply
using Unitful: Unitful, Quantity, ustrip, rad, @u_str, °, km, Units, NoUnits

# From deps
export °, km, @u_str # From Unitful
export to_degrees, to_meters # From BasicTypes
export Identity # From TransformsBase

include("types/abstract_types.jl")
export AbstractSatcomCoordinate, AngularPointing, AbstractPointing, AbstractCRSTransform, AbstractFieldValue, AbstractPosition
public AbstractPointingOffset

include("types/traits.jl")

include("types/pointing.jl")
export PointingVersor, UV, ThetaPhi, AzEl, AzOverEl, ElOverAz

include("types/pointing_offsets.jl") 
public PointingOffset

include("types/geocentric.jl") 
export ECEF, ECI, LLA 

include("types/topocentric.jl") 
export ENU, NED, AER 

include("types/local.jl") 
export LocalCartesian, GeneralizedSpherical 

include("types/transforms.jl") 
export CRSRotation, BasicCRSTransform, InverseTransform 

include("types/type_aliases.jl") 
export Spherical, AzElDistance

include("functions/traits.jl")

include("functions/pointing.jl")
include("functions/pointing_offsets.jl")
export get_angular_distance, get_angular_offset, add_angular_offset

include("functions/geocentric.jl")
include("functions/topocentric.jl")
include("functions/local.jl")
include("functions/transforms.jl")
public origin, rotation

include("functions/fieldvalues.jl")

include("utils.jl")
export numbertype, enforce_numbertype, has_numbertype, change_numbertype, default_numbertype, raw_properties, raw_svector, raw_properties

include("functions/fallbacks.jl")

end # module SatComCoordinates