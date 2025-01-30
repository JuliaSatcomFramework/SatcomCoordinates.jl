module SatcomCoordinates

using BasicTypes: BasicTypes, constructor_without_checks, to_degrees, to_meters, Met, Deg, Rad, UnitfulAngleQuantity, °, ValidAngle, Point2D, Point3D, Point, PS, ValidDistance, to_radians
using ConstructionBase: ConstructionBase, getfields
using StaticArrays: StaticArrays, FieldVector, SVector, @SVector
using LinearAlgebra: LinearAlgebra, normalize, norm
using Random: Random, SamplerType, AbstractRNG
using Unitful: Unitful, Quantity, ustrip, rad

include("abstract_types.jl")
export AbstractSatcomCoordinate, CartesianPosition, LengthCartesian, AngularPointing, AbstractPointing

include("pointing/types.jl")
export PointingVersor, UV, ThetaPhi, AzOverEl, ElOverAz

include("geocentered/types.jl")
export ECEF, ECI, LLA

include("union_types.jl")

include("pointing/functions.jl") # Contains constructors, conversions and rand methods
export get_angular_distance

include("geocentered/functions.jl")

include("utils.jl")
export numbertype

end # module SatComCoordinates