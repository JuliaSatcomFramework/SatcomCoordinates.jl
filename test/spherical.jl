@testsnippet setup_spherical begin
    using SatcomCoordinates
    using SatcomCoordinates: tuplecoords, ncoords
    using SatcomCoordinates.LinearAlgebra
    using SatcomCoordinates.StaticArrays
    using SatcomCoordinates.BasicTypes
    using SatelliteToolboxTransformations
    using Test
    using TestAllocations
end

@testitem "SphericalCRS" setup=[setup_spherical] begin
    @test getcrs(pointingcrs, SphericalCRS()) == ThetaPhi()
    @test getcrs(pointingcrs, SphericalCRS(AzEl())) == AzEl()

    # We test constructor of coordinate from CRS type
    sph = SphericalCRS(1,2,3)
    @test sph isa Coordinate{<:SphericalCRS}
    @test getcrs(pointingcrs, sph) == ThetaPhi()
    # We test constructor with tuple directly
    @test sph == SphericalCRS((1,2,3))

    # Test construction from the CRS instance
    sph_crs = SphericalCRS(ThetaPhi())
    @test sph_crs(1,2,3) == sph

    # We test extraction of the pointing
    @test change_crs(ThetaPhi(), sph) == ThetaPhi(1,2)
    @test change_crs(AzEl(), sph) == change_crs(AzEl(), ThetaPhi(1,2))

    # We test that if the pointing and spherical CRSs have different linked cartesian we get an error
    @test_throws "No conversion is defined" change_crs(AzEl(ECEF()), sph)

    # We do an even more complicated test which hits the path where cartesian CRS type is the same but the actual instances are not
    sph_crs = SphericalCRS(ThetaPhi(NED(LLA(0,0,1200km))))
    azel_crs = AzEl(NED(LLA(0,10,1200km)))
    @test_throws "not derived from the same" change_crs(azel_crs, sph_crs(1,2,3))

    @test crs(rand(sph_crs)) == sph_crs
    @test rand(sph_crs).distance <= 1u"m"

    # We test conversion to and from the base CRS
    sph_crs = SphericalCRS()
    sph = sph_crs(0,0,1)
    @test change_crs(sph_crs, Cartesian(0,0,1)) ≈ sph
    @test change_crs(Cartesian(), sph) ≈ Cartesian(0,0,1)

    @testset "Allocations" begin
        @testset "Constructor" begin
            @test @nallocs(SphericalCRS(1,2,3)) == 0
            @test @nallocs(SphericalCRS(SA[1f0,2f0,3f0])) == 0
            @test @nallocs(SphericalCRS((1,2,3f0))) == 0
            @test @nallocs(SphericalCRS(1,2,3) |> change_valuetype(Float32)) == 0
        end

        @testset "Conversion" begin
            @test @nallocs(change_crs(sph_crs, Cartesian(0,0,1))) == 0
            @test @nallocs(change_crs(Cartesian(), sph)) == 0

            @test @nallocs(change_crs(AzEl(), sph)) == 0
            @test @nallocs(change_crs(SphericalCRS(AzEl()), sph)) == 0
        end
    end
end