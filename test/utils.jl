@testitem "numbertype" begin
    using SatcomCoordinates: numbertype, has_numbertype
    using SatcomCoordinates.Unitful

    @test has_numbertype(UV) === false
    @test has_numbertype(UV{Float32}) === true

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
    @test numcoords(rand(UV)) === 2
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
    @test wrap_spherical_angles((-10°, 150), ElOverAz) == (170°, -30°)
end

