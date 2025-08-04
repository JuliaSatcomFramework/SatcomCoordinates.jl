@testsnippet setup_transforms begin 
    using SatcomCoordinates
    using SatcomCoordinates: tuplecoords, ncoords, coords
    using SatcomCoordinates.LinearAlgebra
    using SatcomCoordinates.StaticArrays
    using SatcomCoordinates.BasicTypes
    using SatcomCoordinates.PlutoShowHelpers
    using Test
    using TestAllocations
end

@testitem "getcrstransform" setup=[setup_transforms] begin
    using SatcomCoordinates

    # We first create a NED CRS at a specific location above Earth
    enu_crs = ENU(LLA(0, 0, 1200km))

    # We then create a Spherical CRS (AzEl) that is linked to the ENU CRS. This is a double nested CRS as it's itself based on a ENU which is based on an ECEF CRS.
    aer_crs = SphericalCRS(AzEl(enu_crs))

    @test getcrs(linkedcrs, aer_crs) == enu_crs # The linked CRS is the one immediately below the provided CRS, which is the ENU CRS

    @test getcrs(rootcrs, aer_crs) == ECEF() # The root CRS is the one at the bottom of the nested CRS, which is the ECEF CRS

    # Extract the transformation towards the linked CRS (NED)
    tlinked = getcrstransform(linkedcrs, aer_crs)

    # 90° el, 10m distance is (0,0,10) in ENU
    @test tlinked(aer_crs(0, 90, 10)) ≈ enu_crs(0, 0, 10) # The transformation is applied to the coordinate

    # We now extract the transformation towards the root CRS (ECEF)
    troot = getcrstransform(rootcrs, aer_crs)

    # Check that the origin is correctly transformed
    @test troot(aer_crs(0, 90, 0)) ≈ ecef_origin(aer_crs)
end