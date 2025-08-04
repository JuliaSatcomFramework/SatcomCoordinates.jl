@testsnippet setup_transforms begin 
    using SatcomCoordinates
    using SatcomCoordinates: tuplecoords, ncoords, coords, RawComposedTransform
    using SatcomCoordinates.LinearAlgebra
    using SatcomCoordinates.StaticArrays
    using SatcomCoordinates.Rotations
    using SatcomCoordinates.BasicTypes
    using SatcomCoordinates.TransformsBase: TransformsBase, identity, inverse, isinvertible, isrevertible, apply
    using SatcomCoordinates.PlutoShowHelpers
    using SatelliteToolboxTransformations
    using Test
    using TestAllocations
end

@testitem "getcrstransform" setup=[setup_transforms] begin
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

@testitem "RawAffineTransform" setup=[setup_transforms] begin

    # We create a random rotation matrix
    translation = SVector(10,0,0)

    # We create a random translation vector
    rotation = RotZ(90u"°")

    rawrotation = RawRotation(rotation)
    rawtranslation = RawTranslation(translation)

    @test isinvertible(rawrotation)
    @test isrevertible(rawrotation)

    # We test inversion of either pure rotation or pure translation will keep it pure
    @test inverse(rawrotation) isa RawRotation
    @test inverse(rawtranslation) isa RawTranslation

    @test rawrotation(SA_F64[0,0,10] |> Tuple) |> SVector ≈ SA_F64[0,0,10] # Rotating around Z doesn't do anything here
    @test rawtranslation(SA_F64[0,0,10] |> Tuple) |> SVector ≈ SA_F64[10,0,10] # Rotating around Z doesn't do anything here
end

@testitem "RawComposedTransform" setup=[setup_transforms] begin
    # We create a random rotation matrix
    translation = SVector(10,0,0)

    # We create a random translation vector
    rotation = RotZ(90u"°")

    rawrotation = RawRotation(rotation)
    rawtranslation = RawTranslation(translation)

    composed1 = RawComposedTransform(rawrotation, rawtranslation)
    composed2 = RawComposedTransform(rawtranslation, rawrotation)

    # The specific composed1 is actually affine, but we don't consider this affine in general as this type is only used constructed internally as part of `compose` and that always returns directly a `RawAffineTransform` when combining two affine transforms
    @test !isaffinetransform(composed1)

    @test TransformsBase.parameters(composed1) == (;t1 = rawrotation, t2 = rawtranslation)
    @test TransformsBase.parameters(composed2) == (;t1 = rawtranslation, t2 = rawrotation)

    @test isinvertible(composed1)
    @test isrevertible(composed1)

    @test isinvertible(composed2)
    @test isrevertible(composed2)

    affine1 = RawAffineTransform(rotation, translation)
    # By default, in a RawAffineTransform the rotation is applied before the translation, so we have to create the Affine equivalent to `composed2` by directly using compose
    affine2 = compose(rawtranslation, rawrotation)

    @test affine1 isa RawAffineTransform
    @test isaffinetransform(affine1)

    for _ in 1:10
        tup = Tuple(rand(3))
        @test SVector(affine1(tup)) ≈ SVector(composed1(tup))
        @test SVector(affine2(tup)) ≈ SVector(composed2(tup))
    end
end

@testitem "CRSTransform" setup=[setup_transforms] begin
    sph_crs = SphericalCRS()
    cart_crs = Cartesian()

    tsph = getcrstransform(rootcrs, sph_crs)
    tsph_raw = SatcomCoordinates.raw_transform(tsph)

    @test SatcomCoordinates.output_crs(tsph) == cart_crs
    @test SatcomCoordinates.input_crs(tsph) == sph_crs
    @test tsph_raw isa SatcomCoordinates.SphericalToCartesian

    # Other misc tests for coverage
    @test isinvertible(tsph)
    @test isrevertible(tsph)

    @test SatcomCoordinates.israwtransform(tsph) == false

    for _ in 1:10
        rs = rand(sph_crs)
        @test rs |> tsph |> inverse(tsph) ≈ rs
    end

    @test TransformsBase.parameters(tsph) == (;crsₒ = cart_crs, crsᵢ = sph_crs, raw = tsph_raw)
end

@testitem "Compose" setup=[setup_transforms] begin

    @test compose(rand(RawAffineTransform), rand(RawTranslation)) isa RawAffineTransform
    @test compose(rand(RawAffineTransform), rand(RawRotation)) isa RawAffineTransform
    @test compose(rand(RawTranslation), rand(RawAffineTransform)) isa RawAffineTransform
    @test compose(rand(RawRotation), rand(RawAffineTransform)) isa RawAffineTransform

    sph2c = getcrstransform_raw(linkedcrs, SphericalCRS())
    afft = rand(RawAffineTransform)

    composed1 = compose(sph2c, afft)
    composed2 = compose(afft, sph2c)

    c1valid = compose(composed1, rand(RawAffineTransform))
    @test c1valid isa RawComposedTransform
    @test c1valid.t1 == composed1.t1

    @test_throws "if both `t1.t2` and `t2` are affine transforms" compose(composed2, rand(RawAffineTransform))
    @test_throws "if both `t1` and `t2.t1` are affine transforms" compose(rand(RawAffineTransform), composed1)

    c2valid = compose(rand(RawAffineTransform), composed2)
    @test c2valid isa RawComposedTransform
    @test c2valid.t2 == composed2.t2

    @test_throws "are the Identity" compose(composed1, composed2)

    # We test that composing with identity in the middle works
    c1 = compose(sph2c, Identity())
    c2 = compose(Identity(), inverse(sph2c))

    cid = SatcomCoordinates._compose(c1, c2)
    @test cid.t1 == sph2c
    @test cid.t2 == inverse(sph2c)

    for _ in 1:10
        rs = rand(3) |> Tuple
        @test SVector(cid(rs)) ≈ SVector(rs)
    end
end