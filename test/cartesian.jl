@testsnippet setup_cartesian begin
    using SatcomCoordinates
    using SatcomCoordinates: raw_rotation, raw_translation, raw_linkedcrs_transform, tuplecoords
    using Test
    using SatcomCoordinates.LinearAlgebra
    using SatcomCoordinates.StaticArrays
    using SatcomCoordinates.BasicTypes
    using SatcomCoordinates.Rotations
    using TestAllocations
end

@testitem "AffineCartesian" setup=[setup_cartesian] begin
    # This will test a use case of AffineCartesian to represent multiple connected cartesian CRSs for the modelling of a reflector antenna

    root = Cartesian() # This is the basic CRS

    feed_cartesian_crs = AffineCartesian(root, Cartesian(), rand(RawAffineTransform))
    feed_spherical_crs = SphericalCRS(ThetaPhi(feed_cartesian_crs))

    antenna_crs = AffineCartesian(root, Cartesian(), rand(RawAffineTransform))

    # We create a point at the origin of the antenna CRS, which assume to represent also a point on the antenna surface
    antenna_surface_point = antenna_crs(0,0,0)

    # For computing the electric field at a specific point on the antenna surface, we need the coordinate of the point in spherical coordinates from the feed CRS
    feed_referenced_surface_point = change_crs(feed_spherical_crs, antenna_surface_point)

    @test feed_referenced_surface_point.distance > 0u"m"

    # We test that the antenna origin corresponds to it's translation w.r.t the root CRS
    antenna_origin_root = change_crs(Cartesian(), antenna_surface_point)
    antenna_sv = tuplecoords(antenna_origin_root) |> SVector
    @test raw_translation(antenna_crs |> raw_linkedcrs_transform) == antenna_sv

    # We test that when converting the antenna origin expressed in the spherical coordinates from the feed CRS, the resulting point is the same
    @test antenna_origin_root ≈ change_crs(Cartesian(), feed_referenced_surface_point)

    @testset "Allocations" begin
        @test @nallocs(AffineCartesian(root, Cartesian(), rand(RawAffineTransform))) == 0
        @test @nallocs(change_crs(Cartesian(), antenna_surface_point)) == 0
        @test @nallocs(change_crs(Cartesian(), feed_referenced_surface_point)) == 0
    end
end