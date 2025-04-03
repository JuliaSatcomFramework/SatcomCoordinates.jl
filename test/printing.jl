@testsnippet setup_printing begin
    using SatcomCoordinates.PlutoShowHelpers
    using SatcomCoordinates.PlutoShowHelpers: shortname, show_namedtuple, repl_summary
    using SatcomCoordinates: UVOffset, ThetaPhiOffset
end

@testitem "Printing" setup=[setup_printing] begin

    s = repr(rand(Spherical))
    @test contains(s, "Spherical")

    s = repr(rand(AzElDistance))
    @test contains(s, "AzElDistance")

    s = repr(rand(GeneralizedSpherical{AzOverEl, Float64}))
    @test contains(s, "AzOverEl")

    s = repr(MIME"text/plain"(), rand(ECEF))
    @test contains(s, "ECEF Coordinate")
    @test contains(s, "x = ")

    s = repr(MIME"text/plain"(), rand(LLA))
    @test contains(s, "LLA Coordinate")
    @test contains(s, "lat = ")

    s = repr(MIME"text/plain"(), rand(BasicCRSTransform))
    contains(s, "LocalCartesian")

    s = repr(MIME"text/plain"(), rand(ThetaPhi))
    @test contains(s, "ThetaPhi Pointing")
    @test contains(s, "θ = ")

    s = repr(MIME"text/plain"(), rand(PointingVersor))
    @test contains(s, "PointingVersor")
    @test contains(s, "x = ")
    @test contains(s, "y = ")
    @test contains(s, "z = ")

    s = repr(MIME"text/plain"(), rand(UVOffset))
    @test contains(s, "UV Pointing Offset")
    @test contains(s, "u = ")
    @test contains(s, "v = ")

    s = repr(MIME"text/plain"(), rand(ThetaPhiOffset))
    @test contains(s, "ThetaPhi Pointing Offset")
    @test contains(s, "θ = ")
    @test contains(s, "φ = ")

    @test_logs (:warn, r"show_outside_pluto") repr(MIME"text/html"(), rand(LLA))
end
