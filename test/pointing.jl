@testsnippet setup_pointing begin
    using SatcomCoordinates
    using SatcomCoordinates: tuplecoords, ncoords
    using SatcomCoordinates.LinearAlgebra
    using SatcomCoordinates.StaticArrays
    using SatcomCoordinates.BasicTypes
    using Test
    using TestAllocations
end

@testitem "DirectionCosines" setup=[setup_pointing] begin
    p = DirectionCosines(rand(3)...)
    @test hypot(tuplecoords(p)...) ≈ 1

    @test ncoords(DirectionCosines) == 3 == length(p |> tuplecoords)

    @test_throws "is not a valid property" rand(DirectionCosines()).q

    # Specifying numbertype
    @test valuetype(p) == Float64
    # Test that default numbertype is Float64
    @test change_valuetype(Float32, p) |> valuetype == Float32
    # Test various constructors
    @test DirectionCosines(1,2,3) == DirectionCosines((1,2,3)) == DirectionCosines(SVector{3,Float64}(1,2,3))
    # Test different types
    p = DirectionCosines((0.0, 0, 1f0))
    @test p.z == 1.0 && p.z isa Float64

    @test map(-, tuplecoords(p)) == tuplecoords(-p)

    # Test some randomness properties
    @testset "rand" begin
        NPTS = 1000
        v = rand(DirectionCosines(), NPTS)
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
        @test @nallocs(DirectionCosines(1,2,3)) == 0
        @test @nallocs(DirectionCosines(SVector(1f0,2f0,3f0))) == 0
        @test @nallocs(DirectionCosines((1,2,3f0))) == 0
        @test @nallocs(DirectionCosines(1,2,3) |> change_valuetype(Float32)) == 0

        p = rand(DirectionCosines())
        # Check that custom getproperty does not allocate
        f(p) = (p.u, p.v, p.w)
        @test @nallocs(f(p)) == 0
    end
end

@testitem "UV" setup=[setup_pointing] begin
    using SatcomCoordinates: UV_CONSTRUCTOR_TOLERANCE
    uv = UV(0,0)
    @test valuetype(uv) == Float64
    @test ncoords(UV) == 2

    @test change_valuetype(Float32, uv) |> valuetype == Float32

    @test UV(sqrt(1 + 1e-5), 0).u == 1
    @test_throws "tolerance" UV(sqrt(1+1.1e-5), 0)

    UV_CONSTRUCTOR_TOLERANCE[] = 0
    @test_throws "tolerance" UV(1 + 1e-10, 10)
    UV_CONSTRUCTOR_TOLERANCE[] = 1e-5

    # Test Constructors with tuple or SVector
    @test UV(1,0) == UV((1,0)) == UV(SVector(1,0))

    # Test randomness
    @testset "rand" begin
        NPTS = 1000
        v = rand(UV(), NPTS)
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
        @test @nallocs(UV(1,0) |> change_valuetype(Float32)) == 0
        @test @nallocs(UV(((1,0)))) == 0
        @test @nallocs(UV(SVector(1,0))) == 0
    end
end

@testitem "ThetaPhi" setup=[setup_pointing] begin
    tp = ThetaPhi(0,0)
    @test tp isa Coordinate{<:ThetaPhi}
    @test ncoords(ThetaPhi) == 2
    @test valuetype(tp) == Float64
    @test tp.θ == 0°
    @test tp.φ == 0°
    @test tp.θ isa Deg{Float64}
    @test tp.φ isa Deg{Float64}

    @test_throws "is not a valid property" rand(ThetaPhi()).q

    tp = ThetaPhi(1,0) |> change_valuetype(Float32)
    @test valuetype(tp) == Float32
    @test tp.θ isa Deg{Float32}
    @test tp.θ ≈ 1° 

    @test ThetaPhi(1,0) == ThetaPhi((1,0)) == ThetaPhi(SVector(1,0)) 

    # Test wrapping
    tp = ThetaPhi(-45, 0)
    @test tp.θ ≈ 45°
    @test tp.φ ≈ -180°

    tp = ThetaPhi(270, -30)
    @test tp.θ ≈ 90°
    @test tp.φ ≈ 150°

    tp = ThetaPhi(100, 130) # No wrapping
    @test tp.theta ≈ 100° # We also use the alias for theta
    @test tp.phi ≈ 130° # We also use the alias for phi

    # Test some randomness
    @testset "rand" begin
        NPTS = 1000
        v = rand(ThetaPhi(), NPTS)
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
        @test @nallocs(ThetaPhi(1,0) |> change_valuetype(Float32)) == 0
        @test @nallocs(ThetaPhi(((1,0)))) == 0
        @test @nallocs(ThetaPhi(SVector(1,0))) == 0

        f(tp) = (tp.t, tp.p)
        @test @nallocs(f(tp)) == 0
    end

    @testset "expected_angles" begin
        # Test expected angle signs
        function expected_angles(tp::Coordinate{<:ThetaPhi}, p::Coordinate{<:DirectionCosines})
            valid_theta = if p.z >= 0
                0° <= tp.θ < 90°
            else
                90° <= tp.θ < 180°
            end
            valid_phi = if p.y >= 0
                if p.x >= 0
                    0° <= tp.φ < 90°
                else
                    90° <= tp.φ < 180°
                end
            else
                if p.x >= 0
                    -90° <= tp.φ < 0°
                else
                    -180° <= tp.φ < -90°
                end
            end
            valid = valid_theta && valid_phi
            valid || (@info "Invalid angles: " tp p)
            return valid
        end
        npts = 100
        for _ in 1:npts
            p = rand(DirectionCosines())
            tp = change_crs(ThetaPhi(), p)
            @test expected_angles(tp, p)
        end
    end
end

@testitem "AzOverEl/ElOverAz/AzEl" setup=[setup_pointing] begin
    for P in (AzOverEl, ElOverAz, AzEl)
        @test ncoords(P) == 2
        p = P(1,2)
        @test p isa Coordinate{<:P}
        @test valuetype(p) == Float64
        @test p.az == 1°
        @test p.el == 2°
        @test p.az isa Deg{Float64}

        @test_throws "is not a valid property" rand(P()).q

        # Test constructors with tuple or SVector
        @test P(1,2) == P((1,2)) == P(SVector(1,2))
        # Test wrapping
        p = P(-180, 180)
        @test p.az ≈  0°
        @test p.el ≈ 0°

        p = P(-45, -90) # No wrapping
        @test p.az ≈ -45°
        @test p.el ≈ -90°

        p = P(-60, 130)
        @test p.az ≈ 120°
        @test p.el ≈ -50°

        # Test some randomness
        @testset "rand" begin
            NPTS = 1000
            v = rand(P(), NPTS)
            @test .4 * NPTS < count(p -> p.az > 0, v) < .6 * NPTS
            @test .4 * NPTS < count(p -> p.el > 0, v) < .6 * NPTS

            @test 175° ≤ maximum(p -> p.az, v) ≤ 180°
            @test -180° ≤ minimum(p -> p.az, v) ≤ -175°

            @test 85° ≤ maximum(p -> p.el, v) ≤ 90°
            @test -90° ≤ minimum(p -> p.el, v) ≤ -85°
        end
    end
    @testset "Allocations" begin
        # We need to separate per type here to avoid phantom allocations when shadowing the type with a variable (e.g. `P = ElOverAz`)
        @test @nallocs(ElOverAz(1,0)) == 0
        @test @nallocs(ElOverAz(1f0,0f0)) == 0
        @test @nallocs(ElOverAz((1,0))) == 0
        @test @nallocs(ElOverAz(SVector(1,0))) == 0

        @test @nallocs(AzOverEl(1,0)) == 0
        @test @nallocs(AzOverEl(1f0,0f0)) == 0
        @test @nallocs(AzOverEl((1,0))) == 0
        @test @nallocs(AzOverEl(SVector(1,0))) == 0

        @test @nallocs(AzEl(1,0)) == 0
        @test @nallocs(AzEl(1f0,0f0)) == 0
        @test @nallocs(AzEl((1,0))) == 0
        @test @nallocs(AzEl(SVector(1,0))) == 0
    end

    @testset "AzOverEl expected_angles" begin
        # Test expected angle signs
        function expected_angles(x::Coordinate{<:AzOverEl}, p::Coordinate{<:DirectionCosines})
            valid_el = if p.z >= 0
                if p.y >= 0
                    0° <= x.el <= 90°
                else
                    -90° <= x.el <= 0°
                end
            else
                if p.y >= 0
                    -90° <= x.el <= 0°
                else
                    0° <= x.el <= 90°
                end
            end
            valid_az = if p.z >= 0
                if p.x < 0
                    0° <= x.az <= 90°
                else
                    -90° <= x.az <= 0°
                end
            else
                if p.x < 0
                    90° <= x.az <= 180°
                else
                    -180° <= x.az <= -90°
                end
            end
            valid = valid_el && valid_az
            valid || (@info "Invalid angles: " x p)
            return valid
        end
        npts = 100
        @test all(1:npts) do _
            x = rand(AzOverEl())
            p = change_crs(DirectionCosines(), x)
            expected_angles(x, p)
        end
    end

    @testset "ElOverAz expected_angles" begin
        # Test expected angle signs
        function expected_angles(x::Coordinate{<:ElOverAz}, p::Coordinate{<:DirectionCosines})
            valid_el = if p.y >= 0
                0° <= x.el <= 90°
            else
                -90° <= x.el <= 0°
            end
            valid_az = if p.z >= 0
                if p.x < 0
                    0° <= x.az <= 90°
                else
                    -90° <= x.az <= 0°
                end
            else
                if p.x < 0
                    90° <= x.az <= 180°
                else
                    -180° <= x.az <= -90°
                end
            end
            valid = valid_el && valid_az
            valid || (@info "Invalid angles: " x p)
            return valid
        end
        npts = 100
        @test all(1:npts) do _
            x = rand(ElOverAz())
            p = change_crs(DirectionCosines(), x)
            expected_angles(x, p)
        end
    end

    @testset "AzEl expected_angles" begin
        # Test expected angle signs
        function expected_angles(x::Coordinate{<:AzEl}, p::Coordinate{<:DirectionCosines})
            valid_el = if p.z >= 0
                0° <= x.el <= 90°
            else
                -90° <= x.el <= 0°
            end
            valid_az = if p.x >= 0
                if p.y >= 0
                    0° <= x.az <= 90°
                else
                    90° <= x.az <= 180°
                end
            else
                if p.y >= 0
                    -90° <= x.az <= 0°
                else
                    -180° <= x.az <= -90°
                end
            end
            valid = valid_el && valid_az
            valid || (@info "Invalid angles: " x p)
            return valid
        end
        npts = 100
        @test all(1:npts) do _
            x = rand(AzEl())
            p = change_crs(DirectionCosines(), x)
            expected_angles(x, p)
        end
    end
end

@testitem "Pointing Negation" begin
    p = rand(DirectionCosines())
    @test -p ≈ DirectionCosines(-p.u, -p.v, -p.w)
    for P in (AzEl, AzOverEl, ElOverAz, ThetaPhi)
        @test all(1:100) do _
            ap = rand(P())
            change_crs(DirectionCosines(), -ap) ≈ -change_crs(DirectionCosines(), ap)
        end
    end
end

@testitem "isapprox/convert" setup=[setup_pointing] begin
    types = (DirectionCosines, ThetaPhi, AzOverEl, ElOverAz, UV, AzEl)
    for P in types
        p = rand(P())
        pNaN = P(ntuple(i -> NaN, ncoords(P())))
        @test isnan(pNaN)
        for V in setdiff(types, (P, UV)) # We skip UV due to half-hemisphere errors
            v = change_crs(V(), p)
            @test v ≈ p # Test forward conversion
            @test change_crs(P(), v) ≈ p # Test reverse conversion
            @test @nallocs(change_crs(P(), v)) == 0
        end
        for V in setdiff(types, (P,)) # We skip UV due to half-hemisphere errors
            # We test that NaNs are progagated
            @test isnan(change_crs(V(), pNaN))
            @test @nallocs(change_crs(V(), pNaN)) == 0
        end
    end

    for P in setdiff(types, (UV,))
        p = change_crs(P(), DirectionCosines(0,0,-1))
        @test_throws "half-hemisphere" change_crs(UV(), p)
    end

    @testset "AzEl <-> ThetaPhi" begin
        @test all(1:100) do _
            tp = rand(ThetaPhi())
            p = change_crs(DirectionCosines(), tp)
            ae = change_crs(AzEl(), tp)
            fwd_valid =  ae ≈ p
            tp′ = change_crs(ThetaPhi(), ae)
            rtn_valid = tp′ ≈ tp
            wrap_valid = -180° <= ae.az <= 180° && -180° <= tp.φ <= 180°
            return fwd_valid && rtn_valid && wrap_valid
        end
    end
end
