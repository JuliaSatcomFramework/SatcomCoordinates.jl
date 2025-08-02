@testsnippet setup_raw begin
    using SatcomCoordinates
    using SatcomCoordinates: tuplecoords, ncoords, coords, rawcoords
    using SatcomCoordinates.LinearAlgebra
    using SatcomCoordinates.StaticArrays
    using SatcomCoordinates.BasicTypes
    using SatcomCoordinates.ConstructionBase
    using SatcomCoordinates.PlutoShowHelpers
    using Test
end

@testitem "Raw" setup=[setup_raw] begin
    for P in (Cartesian, SphericalCRS) 
        crs = P()
        coord = rand(crs)
        raw = Raw(coord)
        @test coords(raw) == rawcoords(coord)
        @test propertynames(raw) == propertynames(coord)

        @test SVector(raw) ≈ SVector(tuplecoords(coord))
    end
end