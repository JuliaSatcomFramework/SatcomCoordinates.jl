module BasicCoordinates

using BasicTypes: BasicTypes, constructor_without_checks, to_degrees, to_meters, Met, Deg, Rad, UnitfulAngleQuantity, °
using StaticArrays: StaticArrays, FieldVector, SVector, promote_tuple_eltype, has_eltype, has_size, need_rewrap, Args
using LinearAlgebra: normalize, norm
using Unitful: Unitful, Quantity

include("abstract_types.jl")
export FieldVectorCoordinate, LengthCartesian, NonSVectorCoordinate, AngularPointing

include("pointing.jl")
export PointingVersor, UV, ThetaPhi, AzOverEl

include("utils.jl")
export numbertype

end # module BasicCoordinates
