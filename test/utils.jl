@testitem "numbertype" begin
    using SatcomCoordinates: numbertype, has_numbertype
    using SatcomCoordinates.Unitful
    using SatcomCoordinates.StaticArrays

    @test has_numbertype(UV) === false
    @test has_numbertype(UV{Float32}) === true

    @test numbertype(rand(3)) == Float64
    @test numbertype(@SVector(rand(3))) == Float64

    @test numbertype(1u"°") == Int
    @test numbertype(1.0u"°") == Float64
    @test numbertype(1f0) == Float32
    @test_throws "The numbertype function is not implemented" numbertype(1im)
    @test_throws "numbertype parameter specified" numbertype(UV)
end

@testitem "numcoords" begin
    using SatcomCoordinates: numcoords
    using SatcomCoordinates.Unitful

    @test_throws "The numcoords function is not implemented" numcoords(3)
    @test numcoords(rand(UV)) === 3
    @test numcoords(PointingVersor) === 3
end

@testitem "wrap_spherical_angles" begin
    using SatcomCoordinates: wrap_spherical_angles_normalized, wrap_spherical_angles
    using SatcomCoordinates.Unitful: °

    # For ThetaPhi, the θ angle is forced to be in the [0°, 180°] range
    @test wrap_spherical_angles(10, 30, ThetaPhi) == (10°, 30°)
    @test wrap_spherical_angles((-30, 10°), ThetaPhi) == (30°, -170°)

    # For AzOverEl and ElOverAz, the el angle is forced to be in the [-90°, 90°] range. The az is the first argument
    @test wrap_spherical_angles(30, 10, AzOverEl) == (30°, 10°)
    @test wrap_spherical_angles((-10, 150), ElOverAz) == (170°, -30°)
end

@testitem "Misc" begin
    using SatcomCoordinates: normalize_value, basetype, _convert_different
    using Unitful
    @test normalize_value(1u"°") == deg2rad(1)
    @test normalize_value(1.0u"rad") == 1.0
    @test normalize_value(1u"m") == 1
    @test normalize_value(1f0) == 1f0

    @test basetype(PointingVersor) == PointingVersor
    @test basetype(PointingVersor{Float32}) == PointingVersor
    @test basetype(3.0) == Float64
    @test basetype(rand(LLA)) == LLA

    @test_throws "Cannot convert" _convert_different(PointingVersor, rand(LLA))
end
