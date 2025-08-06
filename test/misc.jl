@testsnippet setup_misc begin
    using SatcomCoordinates
    using SatcomCoordinates: tuplecoords, ncoords, coords, rawcoords, CRSTransform, parse_property_expression
    using SatcomCoordinates.LinearAlgebra
    using SatcomCoordinates.StaticArrays
    using SatcomCoordinates.BasicTypes
    using SatcomCoordinates.ConstructionBase
    using SatcomCoordinates.PlutoShowHelpers
    using SatcomCoordinates.Unitful
    using SatcomCoordinates.TransformsBase: TransformsBase, Identity
    using SatelliteToolboxTransformations
    using Test
end

@testitem "Raw" setup=[setup_misc] begin
    for P in (Cartesian, SphericalCRS) 
        crs = P()
        coord = rand(crs)
        raw = Raw(coord)
        @test coords(raw) == rawcoords(coord)
        @test propertynames(raw) == propertynames(coord)

        @test SVector(raw) ≈ SVector(tuplecoords(coord))
    end
end

@testitem "Errors" setup=[setup_misc] begin
    enu_crs = ENU(LLA(0,0,1200km))
    aer_crs = AER(LLA(0,0,1100km))
    @test_throws "No conversion is defined" change_crs(aer_crs, rand(AzEl(enu_crs)))

    @test_throws "nested" getcrs(pointingcrs, enu_crs)

    @test_throws "Base.(-)" -lla_origin(enu_crs)

    struct CustomCoordinate <: AbstractSatcomCoordinate{Cartesian, Float64, 3} end

    @test_throws "only works between coordinates of the same base type" CustomCoordinate() ≈ Cartesian(1,2,3)
end

@testitem "ncoords" setup=[setup_misc] begin
    @test ncoords(Cartesian()) == 3
    @test ncoords(DirectionCosines) == 3
    @test ncoords(AzEl) == 2
    @test ncoords(Cartesian(1,2,3)) == 3
end

@testitem "macro coverage" setup=[setup_misc] begin
    ei = parse_property_expression(:(a => u"°"))
    @test ei.aliases == Symbol[]

    @test_throws "The macro expect a pair of one of the following forms" parse_property_expression(:(a => u"°" => (3, 2)))
end