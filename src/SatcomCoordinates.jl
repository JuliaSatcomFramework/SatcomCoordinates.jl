module SatcomCoordinates

using BasicTypes: BasicTypes, constructor_without_checks, to_degrees, to_meters, Met, Deg, Rad, UnitfulAngleQuantity, °, ValidAngle, Point2D, Point3D, Point, PS
using StaticArrays: StaticArrays, FieldVector, SVector, @SVector
using LinearAlgebra: normalize, norm
using Random: Random, SamplerType, AbstractRNG
using Unitful: Unitful, Quantity

include("abstract_types.jl")
export CartesianPosition, LengthCartesian, AngularPointing

include("pointing/types.jl")
export PointingVersor, UV, ThetaPhi, AzOverEl, ElOverAz

include("union_types.jl")
export AbstractPointing

include("pointing/functions.jl") # Contains constructors, conversions and rand methods

include("utils.jl")
export numbertype

end # module SatComCoordinates
