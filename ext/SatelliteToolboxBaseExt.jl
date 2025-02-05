module SatelliteToolboxBaseExt

using SatelliteToolboxBase: SatelliteToolboxBase, Ellipsoid
using SatcomCoordinates: SatcomCoordinates, change_numbertype

SatcomCoordinates.change_numbertype(::Type{T}, e::Ellipsoid{T}) where T <: AbstractFloat = return e
SatcomCoordinates.change_numbertype(::Type{T}, e::Ellipsoid) where T <: AbstractFloat = return Ellipsoid{T}(e.a, e.f, e.b, e.e², e.el²)

end