@testsnippet setup_crs_creation begin
    using SatcomCoordinates
    using SatcomCoordinates: tuplecoords, ncoords, coords, raw_linkedcrs_transform
    using SatcomCoordinates.LinearAlgebra
    using SatcomCoordinates.StaticArrays
    using SatcomCoordinates.BasicTypes
    using SatcomCoordinates.PlutoShowHelpers
    using SatcomCoordinates.Rotations
    using SatcomCoordinates.TransformsBase: TransformsBase, Identity, Transform, inverse
    using SatcomCoordinates.ConstructionBase
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
        getcrstype(linkedcrs, _)... # The ... is needed for proper identification by the macro. This simply mirrors the properties of the CRS that is the output of `getcrstype(linkedcrs, _)` where `_` is substituted with the the specific subtype of `NamedCRS`
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
        @test !hascrstrait(ecefcrs, NamedCRS(ECEF(), "test"))

        # To specify that a specific type must forward trait checks to a specific fields it holds, we need to extend the `SatcomCoordinates.crsfield` function for that type.
        SatcomCoordinates.crsfield(::typeof(traitcrs), ::Type{<:NamedCRS}) = :crs
        # The line above is telling the package that when extracting the CRS used for checking trait from the input (which is done with the `traitcrs` function). This is stored in the `:crs` field inside the `NamedCRS` type

        # We probably need invokelatest here as we added a method to the `SatcomCoordinates.crsfield` function not at toplevel but inside the `@testset` block, and this would be a problem in 1.12 without invokelatest
        @test invokelatest(hascrstrait, ecefcrs, NamedCRS(ECEF(), "test"))
    end
end

@testitem "NestedAffine" setup=[setup_crs_creation] begin
    z_trans = RawTranslation((0,0,1))

    z_crss = Any[Cartesian()]
    for i in 2:5
        basecrs = i == 3 ? ECEF() : Cartesian()
        newcrs = AffineCartesian(z_crss[i-1], basecrs, z_trans)
        push!(z_crss, newcrs)
    end
    z_crss = ntuple(i -> z_crss[i], 5)

    @test getcrs(rootcrs, z_crss[5]) === first(z_crss)
    @test getcrs(ecefcrs, z_crss[5]) === z_crss[3]
    @test getcrs(linkedcrs, z_crss[5]) === z_crss[4]

    @test change_crs(Cartesian(), zero(z_crss[5])) == Cartesian(0,0,4)
    @test change_crs(Cartesian(), zero(z_crss[4])) == Cartesian(0,0,3)

    # We can also change_crs with a trait function to extract the coordinate in the first CRS in the nested hierarchy satisfying the trait
    @test change_crs(ecefcrs, zero(z_crss[5])) == z_crss[3](0,0,2)

    @test frameid(z_crss[5]) == EarthDefault()
    @test_throws "does not seem to contain a frame id" frameid(z_crss[2])

    # All the getters function accepting traits can also be used directly with a trait function to pipe
    zero_last = zero(z_crss[5])
    for f in (getcrs, getcrstype, getcrstransform, getcrstransform_raw)
        @test f(ecefcrs, zero_last) == zero_last |> f(ecefcrs)
    end


    @testset "Allocations" begin
        @test @nallocs(change_crs(Cartesian(), zero(z_crss[5]))) == 0
        @test @nallocs(change_crs(Cartesian(), zero(z_crss[4]))) == 0
    end
end

@testitem "ReferenceView" setup=[setup_crs_creation] begin
    # This is an example to create a type representing the view frames from an entity located at a given point on or close to the surface of the earth.

    # This will be based on a specific topocentric as base, on which we are going to build two nested level. First an AttitudeCRS (which is a rotation on the topocentric CRS) and then an AntennaCRS (which is another rotation on top of the CRS specifying the satellite attitude to identify the main CRS the satellite antenna is using for pointing)


    # First we create some helper function to transform valid rotations transforms into a RotMatrix
    process_rotation(T::Type{<:AbstractFloat}, rot::Rotation{3}) = return RawRotation(RotMatrix3{T}(rot))
    process_rotation(::Type{<:AbstractFloat}, ::Identity) = return Identity()
    process_rotation(T::Type{<:AbstractFloat}, rot::RawRotation) = return process_rotation(T, raw_rotation(rot))

    # We create an abstract type for convenience of methods
    abstract type ReferenceViewCRS <: AbstractCRS end

    # This is for extracting valuetype from the topo_crs stored in the nested path
    BasicTypes.valuetype(CRS::Type{<:ReferenceViewCRS}) = return valuetype(getcrstype(topocrs, CRS))

    struct AttitudeCRS{CRS <: AbstractCRS, R <: Transform} <: ReferenceViewCRS 
        topo_crs::CRS
        rot::R
        function AttitudeCRS(topo_crs::AbstractCRS, rot)
            hascrstrait(topocrs, topo_crs) || throw(ArgumentError("The provided CRS does not seem to be a topocentric CRS")) # We check the topo trait at construction rather than constraining tye type parameter in the type definition as we want to allow the user to pass any CRS that satisfies the topo trait even though it's not strictly our existing implementation of topocentric CRSs
            T = common_valuetype(AbstractFloat, Float64, topo_crs)
            rot = process_rotation(T, rot)
            new{typeof(topo_crs), typeof(rot)}(topo_crs, rot)
        end
    end

    # We define a trait identifying the attitudecrs
    attitudecrs(CRS::Type{<:AttitudeCRS}) = return CRS

    # We now define the AntennaCRS type which is a rotation on top of the AttitudeCRS
    struct AntennaCRS{CRS <: AbstractCRS, R <: Transform} <: ReferenceViewCRS 
        att_crs::CRS
        rot::R
        function AntennaCRS(att_crs::AbstractCRS, rot)
            hascrstrait(attitudecrs, att_crs) || throw(ArgumentError("The provided CRS does not seem to be an attitude CRS")) # We check the attitudecrs trait at construction rather than constraining tye type parameter in the type definition as we want to allow the user to pass any CRS that satisfies the attitudecrs trait even though it's not strictly our existing implementation of attitude CRSs
            T = common_valuetype(AbstractFloat, Float64, att_crs)
            rot = process_rotation(T, rot)
            new{typeof(att_crs), typeof(rot)}(att_crs, rot)
        end
    end

    # We also add the antennacrs trait
    antennacrs(CRS::Type{<:AntennaCRS}) = return CRS

    # We have the default no-argument constructor for the ReferenceViewCRS
    (CRS::Type{<:ReferenceViewCRS})() = return constructorof(CRS)(AnyCRS(), Identity())

    # We now define the required transformation to the linkedcrs
    function SatcomCoordinates.raw_linkedcrs_transform(crs::ReferenceViewCRS)
        return crs.rot
    end

    # We now define the ReferenceView type, which will is storing the topocentric CRS as well as the attitude and antenna CRSs rotations directly.
    # We go for storing just the raw rotations (or Identity) rather than the full Attitude and Antenna CRSs themselves to avoid storing in memory the originating topocentric CRS three times.
    struct ReferenceView{CRS <: AbstractCRS, R1 <: Transform, R2 <: Transform}
        topo_crs::CRS
        att_rot::R1
        ant_rot::R2
        function ReferenceView(topo_crs::AbstractCRS, att_rot, ant_rot)
            hascrstrait(topocrs, topo_crs) || throw(ArgumentError("The provided CRS does not seem to be a topocentric CRS")) # We check the topo trait at construction rather than constraining tye type parameter in the type definition as we want to allow the user to pass any CRS that satisfies the topo trait even though it's not strictly our existing implementation of topocentric CRSs
            T = common_valuetype(AbstractFloat, Float64, topo_crs)
            att_rot = process_rotation(T, att_rot)
            ant_rot = process_rotation(T, ant_rot)
            new{typeof(topo_crs), typeof(att_rot), typeof(ant_rot)}(topo_crs, att_rot, ant_rot)
        end
    end

    SatcomCoordinates.crs(rv::ReferenceView) = AntennaCRS(AttitudeCRS(rv.topo_crs, rv.att_rot), rv.ant_rot)

    struct AnyCRS <: AbstractCRS end
    SatcomCoordinates.hascrstrait(::Function, ::Type{<:AnyCRS}) = return true

    SatcomCoordinates.getcrstransform_raw(::typeof(antennacrs), rv::ReferenceView) = return Identity()

    SatcomCoordinates.getcrstransform_raw(::typeof(attitudecrs), rv::ReferenceView) = return rv.ant_rot

    SatcomCoordinates.getcrstransform_raw(::typeof(topocrs), rv::ReferenceView) = return compose(getcrstransform_raw(attitudecrs, rv), rv.att_rot)

    SatcomCoordinates.getcrstransform_raw(::typeof(ecefcrs), rv::ReferenceView) = return compose(getcrstransform_raw(antennacrs, rv), raw_linkedcrs_transform(rv.topo_crs))

    function get_ecef(rv::ReferenceView, coord::Coordinate{<:AntennaCRS{<:AnyCRS}})
        rawt = getcrstransform_raw(ecefcrs, rv)
        ecef_crs = getcrs(linkedcrs, rv.topo_crs)
        ntup = rawt(tuplecoords(coord))
        return ecef_crs(ntup...)
    end

    function get_era(rv::ReferenceView, coord::Coordinate{<:ECEF})
        ecef2ant = getcrstransform_raw(ecefcrs, rv) |> inverse
        era_crs = SphericalCRS(AzEl(getcrs(rv)))
        rawt = compose(ecef2ant, raw_linkedcrs_transform(era_crs))
        ntup = rawt(tuplecoords(coord))
        return era_crs(ntup)
    end
end