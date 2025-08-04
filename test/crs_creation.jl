@testsnippet setup_crs_creation begin
    using SatcomCoordinates
    using SatcomCoordinates: tuplecoords, ncoords, coords
    using SatcomCoordinates.LinearAlgebra
    using SatcomCoordinates.StaticArrays
    using SatcomCoordinates.BasicTypes
    using SatcomCoordinates.PlutoShowHelpers
    using Test
    using TestAllocations
end

@testitem "CartesianKm" setup=[setup_crs_creation] begin
    # We show the simplest case of creating a custom Cartesian CRS where the units are km. We will also add custom property names and have the default as aliases

    struct CartesianKm <: AbstractCRS end

    SatcomCoordinates.@define_properties CartesianKm [
        a => u"km" => (x,) # We set a as default name and x as alias
        b => u"km" => (y,) # We set b as default name and y as alias
        c => u"km" => (z,) # We set c as default name and z as alias
    ]

    custom_crs = CartesianKm()

    # This is still considered cartesian as it has three length units as properties
    @test hascrstrait(cartesiancrs, custom_crs)

    coord = custom_crs(1,2,3)

    # We test that both main and alias can be used to access the coordinates and that by default the units are in km

    @test coord.a == coord.x == 1u"km"
    @test coord.b == coord.y == 2u"km"
    @test coord.c == coord.z == 3u"km"

    # We now test that the raw coordinates (i.e. the ones stored in the actual coordinate struct) are actually stored in meters and without unit

    rawcoord = Raw(coord)

    @test rawcoord.a == rawcoord.x == 1000.0
    @test rawcoord.b == rawcoord.y == 2000.0
    @test rawcoord.c == rawcoord.z == 3000.0
end

@testitem "NamedCRS" setup=[setup_crs_creation] begin
    # We now show how to create a custom CRS that is simply wrapping another CRS but adding a name to it to facilitate identification of different instances

    struct NamedCRS{CRS <: AbstractCRS} <: AbstractLinkedCRS{CRS} 
        crs::CRS
        name::String
        NamedCRS(crs::CRS, name::AbstractString) where {CRS <: AbstractCRS} = new{CRS}(crs, name)
    end

    # Here we are saying to simply extract the coordinates and aliases from the wrapped CRS
    SatcomCoordinates.@define_properties NamedCRS [
        getcrstype(linkedcrs, _)... # The ... is needed for proper identification by the macro. This simply mirrors the properties of the CRS that is the output of `linkedcrstype(_)` where `_` is substituted with the the specific subtype of `NamedCRS`
    ]

    @test SatcomCoordinates.units(NamedCRS{Cartesian}) == (; x = u"m", y = u"m", z = u"m")

    # This is also the case because there is a default method for `SatcomCoordinates.units` that simply returns these cartesian units for all abstract CRS types. And the linkedcrs in NamedCRS is taken from the `crs` field which is upper bounded by `AbstractCRS`
    @test SatcomCoordinates.units(NamedCRS) == (; x = u"m", y = u"m", z = u"m")

    # We now test that the units are correctly extracted from the wrapped CRS
    @test SatcomCoordinates.units(NamedCRS{ThetaPhi{Cartesian}}) == (; θ = u"°", φ = u"°")

    # We customize the printing of the CRS name
    PlutoShowHelpers.shortname(crs::NamedCRS) = return crs.name

    # We test that trying to directly create a coordinate with just number fails as the no-argument constructor for this CRS is not defined (and does not make sense)
    @test_throws "no-argument" NamedCRS()

    custom_crs = NamedCRS(SphericalCRS(), "MySpherical")

    # We test that providing the wrong number of coordinates gives an error
    @test_throws "does not match" custom_crs(1,2)

    @test getcrstype(linkedcrs, custom_crs) <: SphericalCRS
    @test getcrs(linkedcrs, custom_crs) == SphericalCRS()

    coord = custom_crs(1,2,3)

    # We check that all the properties of the ThetaPhi spherical are accessible directly
    @test coord.θ == coord.theta == coord.t == 1u"°"
    @test coord.φ == coord.phi == coord.p == coord.ϕ == 2u"°"
    @test coord.r == coord.range == coord.distance == 3u"m"

    s = repr(custom_crs)
    @test contains(s, "MySpherical(")

    s = repr(custom_crs(1,2,3))
    contains(s, r"Coordinate\{(SatcomCoordinates\.)?MySpherical")

    @testset "Traits" begin
        # Here we show how to customize forwarding trait functions to the inner CRS. By default this is done by adding a method to `SatcomCoordinates.traitcrs` for the specific CRS type

        # We start by first checking that if we don't do anything, the trait are checked directly on the NamedCRS (which is not really what we want)

        # This works because the cartesian trait only looks at the units of the properties
        @test hascrstrait(cartesiancrs, NamedCRS(Cartesian(), "test"))
        @test !hascrstrait(cartesiancrs, NamedCRS(AzOverEl(), "test"))

        # If we try to wrap an ECEF CRS, we see that the isecef trait does not work
    end
end