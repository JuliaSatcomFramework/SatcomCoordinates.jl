module SatcomCoordinates

using BasicTypes: BasicTypes, constructor_without_checks, to_degrees, to_meters, Met, Deg, Rad, UnitfulAngleQuantity, ValidAngle, Point2D, Point3D, Point, PS, ValidDistance, to_radians
using ConstructionBase: ConstructionBase, getfields
using StaticArrays: StaticArrays, FieldVector, SVector, @SVector, SA
using LinearAlgebra: LinearAlgebra, normalize, norm
using Random: Random, SamplerType, AbstractRNG
using Unitful: Unitful, Quantity, ustrip, rad, @u_str, °

# From deps
export °

include("types/abstract_types.jl")
export AbstractSatcomCoordinate, CartesianPosition, LengthCartesian, AngularPointing, AbstractPointing

include("types/pointing.jl")
export PointingVersor, UV, ThetaPhi, AzEl, AzOverEl, ElOverAz

include("types/geocentric.jl")
export ECEF, ECI, LLA

include("types/topocentric.jl")
export ENU, NED, AER

include("functions/pointing.jl") # Contains constructors, conversions and rand methods
export get_angular_distance, get_angular_offset, add_angular_offset

include("functions/geocentric.jl")
include("functions/topocentric.jl")
include("functions/fallbacks.jl")

include("utils.jl")
export numbertype

end # module SatComCoordinates