module SatcomCoordinates

using BasicTypes: BasicTypes, constructor_without_checks, to_degrees, to_meters, Met, Deg, Rad, UnitfulAngleQuantity, °, ValidAngle, Point2D, Point3D, Point, PS, ValidDistance, to_radians
using ConstructionBase: ConstructionBase, getfields
using StaticArrays: StaticArrays, FieldVector, SVector, @SVector
using LinearAlgebra: LinearAlgebra, normalize, norm
using Random: Random, SamplerType, AbstractRNG
using Unitful: Unitful, Quantity, ustrip, rad

include("types/abstract_types.jl")
export AbstractSatcomCoordinate, CartesianPosition, LengthCartesian, AngularPointing, AbstractPointing

include("types/pointing.jl")
export PointingVersor, UV, ThetaPhi, AzOverEl, ElOverAz

include("types/geocentered.jl")
export ECEF, ECI, LLA

include("union_types.jl")

include("functions/pointing.jl") # Contains constructors, conversions and rand methods
export get_angular_distance

include("functions/geocentered.jl")

include("utils.jl")
export numbertype

end # module SatComCoordinates