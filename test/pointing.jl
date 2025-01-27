@testsnippet setup_pointing begin
    using SatcomCoordinates: wrap_spherical_angles_normalized, wrap_spherical_angles, numbertype
    using SatcomCoordinates.LinearAlgebra
    using SatcomCoordinates.StaticArrays
    using SatcomCoordinates.BasicTypes
    using TestAllocations
end

@testitem "PointingVersor" setup=[setup_pointing] begin
    p = PointingVersor(rand(3)...)
    @test norm(p) ≈ 1

    # Specifying numbertype
    p = PointingVersor{Float32}(rand(3)...)
    @test numbertype(p) == Float32
    # Test that default numbertype is Float64
    @test numbertype(PointingVersor(1,2,3)) == Float64
    # Test various constructors
    @test PointingVersor(1,2,3) == PointingVersor((1,2,3)) == PointingVersor(SVector{3,Float64}(1,2,3)) == PointingVersor([1,2,3])
    # Test different types
    p = PointingVersor((0.0, 0, 1f0))
    @test p.z == 1.0 && p.z isa Float64

    # Test some randomness properties
    @testset "rand" begin
        NPTS = 1000
        v = rand(PointingVersor, NPTS)
        @test .4 * NPTS < count(p -> p.x > 0, v) < .6 * NPTS
        @test .4 * NPTS < count(p -> p.y > 0, v) < .6 * NPTS
        @test .4 * NPTS < count(p -> p.z > 0, v) < .6 * NPTS

        @test .9 ≤ maximum(p -> p.x, v) ≤ 1
        @test -1 ≤ minimum(p -> p.x, v) ≤ -.9

        @test .9 ≤ maximum(p -> p.y, v) ≤ 1
        @test -1 ≤ minimum(p -> p.y, v) ≤ -.9

        @test .9 ≤ maximum(p -> p.z, v) ≤ 1
        @test -1 ≤ minimum(p -> p.z, v) ≤ -.9
    end

    @testset "Allocations" begin
        @test @nallocs(PointingVersor(1,2,3)) == 0
        @test @nallocs(PointingVersor(SVector(1f0,2f0,3f0))) == 0
        @test @nallocs(PointingVersor((1,2,3f0))) == 0
        @test @nallocs(PointingVersor{Float32}(1,2,3)) == 0

        p = rand(PointingVersor)
        # Check that custom getproperty does not allocate
        f(p) = (p.x, p.y, p.z, p.u, p.v, p.w)
        @test @nallocs(f(p)) == 0
    end
end

@testitem "UV" setup=[setup_pointing] begin
    using SatcomCoordinates: UV_CONSTRUCTOR_TOLERANCE
    uv = UV(0,0)
    @test numbertype(uv) == Float64
    
    @test numbertype(UV{Float32}(1,0)) == Float32

    @test UV(sqrt(1 + 1e-5), 0).u == 1
    @test_throws "tolerance" UV(sqrt(1+1.1e-5), 0)

    UV_CONSTRUCTOR_TOLERANCE[] = 0
    @test_throws "tolerance" UV(1 + 1e-10, 10)
    UV_CONSTRUCTOR_TOLERANCE[] = 1e-5

    # Test Constructors with tuple or SVector/Vector
    @test UV(1,0) == UV((1,0)) == UV(SVector(1,0)) == UV([1,0])

    # Test randomness
    @testset "rand" begin
        NPTS = 1000
        v = rand(UV, NPTS)
        @test .4 * NPTS < count(p -> p.u > 0, v) < .6 * NPTS
        @test .4 * NPTS < count(p -> p.v > 0, v) < .6 * NPTS

        @test .9 ≤ maximum(p -> p.u, v) ≤ 1
        @test -1 ≤ minimum(p -> p.u, v) ≤ -.9

        @test .9 ≤ maximum(p -> p.v, v) ≤ 1
        @test -1 ≤ minimum(p -> p.v, v) ≤ -.9
    end
    
    # Test allocations
    @testset "Allocations" begin
        @test @nallocs(UV(1,0)) == 0
        @test @nallocs(UV{Float32}(1,0)) == 0
        @test @nallocs(UV(((1,0)))) == 0
        @test @nallocs(UV(SVector(1,0))) == 0
    end
end

@testitem "ThetaPhi" setup=[setup_pointing] begin
    tp = ThetaPhi(0,0)
    @test numbertype(tp) == Float64
    @test tp.θ == tp.theta == tp.t == 0
    @test tp.φ == tp.phi == tp.p == 0
    @test tp.θ isa Deg{Float64}

    tp = ThetaPhi{Float32}(1,0)
    @test numbertype(tp) == Float32
    @test tp.θ isa Deg{Float32}
    @test tp.θ == 1°

    @test ThetaPhi(1,0) == ThetaPhi((1,0)) == ThetaPhi(SVector(1,0)) == ThetaPhi([1,0])

    # Test wrapping
    tp = ThetaPhi(-45, 0)
    @test tp.θ ≈ 45°
    @test tp.φ ≈ -180°

    tp = ThetaPhi(270, -30)
    @test tp.θ ≈ 90°
    @test tp.φ ≈ 150°

    tp = ThetaPhi(100, 130) # No wrapping
    @test tp.θ ≈ 100°
    @test tp.φ ≈ 130°

    # Test some randomness
    @testset "rand" begin
        NPTS = 1000
        v = rand(ThetaPhi, NPTS)
        @test .4 * NPTS < count(p -> p.θ > 90°, v) < .6 * NPTS
        @test .4 * NPTS < count(p -> p.φ > 0°, v) < .6 * NPTS

        @test 175° ≤ maximum(p -> p.θ, v) ≤ 180°
        @test 0° ≤ minimum(p -> p.θ, v) ≤ 5°

        @test 175° ≤ maximum(p -> p.φ, v) ≤ 180°
        @test -180° ≤ minimum(p -> p.φ, v) ≤ -175°
    end

    # Allocations
    @testset "Allocations" begin
        @test @nallocs(ThetaPhi(1,0)) == 0
        @test @nallocs(ThetaPhi{Float32}(1,0)) == 0
        @test @nallocs(ThetaPhi(((1,0)))) == 0
        @test @nallocs(ThetaPhi(SVector(1,0))) == 0

        f(tp) = (tp.θ, tp.φ, tp.t, tp.p, tp.theta, tp.phi)
        @test @nallocs(f(tp)) == 0
    end
end

@testitem "AzOverEl" setup=[setup_pointing] begin
    az = AzOverEl(1,2)
    @test numbertype(az) == Float64
    @test az.az ==  az.azimuth == 0
    @test az.el == az.elevation == 0
    @test az.az isa Deg{Float64}
    @test az.el isa Deg{Float64}
end