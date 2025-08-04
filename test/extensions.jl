@testsnippet setup_extensions begin
    using SatcomCoordinates
    using SatcomCoordinates: tuplecoords
    using SatcomCoordinates.StaticArrays
    using Test
    using TestAllocations
end

@testitem "SatelliteToolboxTransformations Extension" setup=[setup_extensions] begin
    using SatelliteToolboxTransformations

    # Test some random fwd and rtn equivalence
    @test all(1:100) do _
        lla = rand(LLA())
        ecef = change_crs(ECEF(), lla)
        lla′ = change_crs(LLA(), ecef)
        lla ≈ lla′
    end

    @testset "Allocations" begin
        @test @nallocs(change_crs(ECEF(), rand(LLA()))) == 0
        @test @nallocs(change_crs(LLA(), rand(ECEF()))) == 0
    end

    e = Ellipsoid(6371e3, 0)

    ellparams = ellipsoidparams(e)
    @test ellparams.b ≈ ellparams.a

    # We test that if we use the Ellipsoid directly as an ID, we don't get equivalent ECEF over the pole
    sph_ecef = ECEF(e)
    sph_lla = LLA(sph_ecef)

    npole = sph_lla(90, 0, 0)
    
    # Simple approx errors because the CRSs are different
    @test_throws "only works between CRSs that are equivalent" change_crs(ECEF(), LLA(90,0,0)) ≉ change_crs(sph_ecef, npole)

    sph_ecef_npole = change_crs(sph_ecef, npole)
    ecef_npole = change_crs(ECEF(), LLA(90,0,0))

    @test Raw(sph_ecef_npole).z ≈ e.a
    @test Raw(ecef_npole).z < e.a - 10e3  # More than 10km off as this is based on WGS84

    # We test now conversion between ECEF and ECI
    ecef = change_crs(ECEF(), LLA(0,0,1200km))

    # We compute the rotation matrix directly using the SatelliteToolboxTransformations package
    eop = fetch_iers_eop()
    jd_utc = 0
    R = r_eci_to_ecef(Val{:J2000}(), Val{:ITRF}(), jd_utc, eop)

    # We test that we can convert directly 
    eci_direct = change_crs(ECI(), ecef; R_eci_to_ecef = R)
    # Alternatively, we can have the code call the function from SatelliteToolboxTransformations to compute the rotation based on jd_utc and eop_data
    eci_indirect = change_crs(ECI(), ecef; jd_utc, eop_data = eop)
    @test eci_direct ≈ eci_indirect

    # We also test with the direct output of SatelliteToolbox
    v = a = zero(SVector{3})
    p = tuplecoords(ecef) |> SVector
    sv = OrbitStateVector(jd_utc, tuplecoords(ecef) |> SVector, v, a)
    sv_eci = sv_ecef_to_eci(sv, ITRF(), J2000(), eop)
    eci_sv = tuplecoords(eci_direct) |> SVector
    @test sv_eci.r ≈ eci_sv

    # We test errors of the eci_to_ecef_rotation
    @test_throws "supplying the correct" change_crs(ECI(), ECEF()(1,2,3); jd_utc)

    # We test that it works for formats that support not providing eop data
    ecef = change_crs(ECEF(), ECI()(1,2,3); jd_utc, ecef_frame = Val{:PEF}())
    @test ecef isa Coordinate{<:ECEF}
end