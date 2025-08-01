@testsnippet setup_printing begin
    using SatcomCoordinates.PlutoShowHelpers
    using SatcomCoordinates.PlutoShowHelpers: shortname, show_namedtuple, repl_summary
end

@testitem "Printing" setup=[setup_printing] begin

    s = repr(rand(SphericalCRS()))
    @test contains(s, "SphericalCRS")

    s = repr(SphericalCRS(AzEl()))
    @test contains(s, "AzEl")

    s = repr(rand(SphericalCRS(AzOverEl())))
    @test contains(s, "AzOverEl")

    s = repr(MIME"text/plain"(), rand(ECEF()))
    @test contains(s, "Coordinate{ECEF")
    @test contains(s, "x = ")

    s = repr(MIME"text/plain"(), rand(LLA()))
    @test contains(s, "Coordinate{LLA")
    @test contains(s, "lat = ")

    s = repr(MIME"text/plain"(), rand(ThetaPhi()))
    @test contains(s, "Pointing{ThetaPhi")
    @test contains(s, "θ = ")

    s = repr(MIME"text/plain"(), AER(rand(LLA())) |> rand)
    @test contains(s, "Coordinate{AER")
    @test contains(s, "az = ")
    @test contains(s, "el = ")
    @test contains(s, "r = ")

    s = repr(MIME"text/plain"(), rand(DirectionCosines()))
    @test contains(s, "Pointing{DirectionCosines")
    @test contains(s, "u = ")
    @test contains(s, "v = ")
    @test contains(s, "w = ")

    @test_logs (:warn, r"show_outside_pluto") repr(MIME"text/html"(), rand(LLA()))
end
