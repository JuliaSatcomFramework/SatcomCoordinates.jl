@testitem "numbertype" begin
    using SatcomCoordinates: numbertype, has_numbertype, enforce_numbertype, to_valid_numbertype
    using SatcomCoordinates.Unitful
    using SatcomCoordinates.StaticArrays

    @test has_numbertype(UV) === false
    @test has_numbertype(UV{Float32}) === true

    @test numbertype(rand(3)) == Float64
    @test numbertype(@SVector(rand(3))) == Float64

    @test numbertype(1u"°") == Int
    @test numbertype(1.0u"°") == Float64
    @test numbertype(1f0) == Float32
    @test_throws "not implemented" numbertype(NoUnits)
    @test_throws "numbertype parameter specified" numbertype(UV)

    @test enforce_numbertype(UV) == UV{Float64} # Provide a default as not present in input type
    @test enforce_numbertype(UV{Float32}) == UV{Float32} # Returns the same input type as it already has a numbertype
    @test enforce_numbertype(UV, Float32) == UV{Float32} # Provide a custom default as not present in input type
    @test enforce_numbertype(UV, 1) == UV{Int64} # Provide a custom default as not present in input type

    @test to_valid_numbertype(Complex{Int}) == Complex{Float64}
    @test_throws "can not be mapped" to_valid_numbertype(UV)
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
    using SatcomCoordinates: basetype, _convert_different
    using Unitful

    @test basetype(PointingVersor) == PointingVersor
    @test basetype(PointingVersor{Float32}) == PointingVersor
    @test basetype(3.0) == Float64
    @test basetype(rand(LLA)) == LLA

    @test_throws "Cannot convert" _convert_different(PointingVersor, rand(LLA))
end

@testitem "change_numbertype" begin
    using SatcomCoordinates: change_numbertype, numbertype, InverseTransform
    using SatcomCoordinates.Unitful
    using SatcomCoordinates.TransformsBase: inverse
    using SatcomCoordinates.StaticArrays

    for T in (LLA, ECEF, UV, ThetaPhi, AzOverEl, ElOverAz, PointingVersor, NED, ENU, AER, LocalCartesian, Spherical, AzElDistance, BasicCRSTransform, CRSRotation)
        x = rand(T)
        @test change_numbertype(Float32, x) isa T{Float32}
        @test change_numbertype(Float64, x) isa T{Float64}
        if x isa BasicCRSTransform
            @test change_numbertype(Float32, inverse(x)) isa InverseTransform{Float32, <:T}
        end
    end

    @test change_numbertype(Float32, 1) === 1f0
    @test change_numbertype(Float32)(1.0) === 1f0

    @test change_numbertype(Float32, 1u"°") === 1f0u"°"
    @test change_numbertype(Float32)(1u"m") === 1f0u"m"

    @test change_numbertype(Float32, SVector(1, 2, 3)) === SVector{3, Float32}(1f0, 2f0, 3f0)
end
