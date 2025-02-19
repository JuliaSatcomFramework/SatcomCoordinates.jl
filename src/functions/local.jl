#### Traits ####
position_trait(::Type{<:GeneralizedSpherical}) = SphericalPositionTrait()

##### Constructors #####

# LocalCartesian
# Handled by generic constructor in fallbacks.jl

# GeneralizedSpherical
function construct_inner_svector(::Type{GeneralizedSpherical{T, P}}, args::Vararg{PS, 3}) where {T <: AbstractFloat, P <: AngularPointing}
    a1, a2, r = args
    p = P{T}(a1, a2)
    r = to_meters(r) |> ustrip
    a1, a2 = raw_svector(p)
    sv = SVector{3, T}(a1, a2, r)
    constructor_without_checks(GeneralizedSpherical{T, P}, sv)
end

##### Base.getproperty #####
# GenerializedSpherical
properties_names(::Type{GeneralizedSpherical{T, P}}) where {T, P} = (property_names(P)..., :r)

##### convert #####
# LocalCartesian <-> GeneralizedSpherical
function _convert_different(::Type{L}, src::G) where {L <: LocalCartesian, G <: GeneralizedSpherical}
    C = enforce_numbertype(L, src)
    (; pointing, r) = src
    p = convert(PointingVersor, pointing)
    (;x, y, z) = raw_svector(p) .* r
    constructor_without_checks(C, x, y, z)
end
function _convert_different(::Type{G}, src::L) where {G <: GeneralizedSpherical, L <: LocalCartesian}
    P = enforce_numbertype(G, src)
    (; x, y, z) = src |> raw_svector
    p = PointingVersor(x, y, z)
    r = norm(raw_svector(src)) * u"m"
    constructor_without_checks(P, p, r)
end

##### Pointing Inversion #####
Base.:(-)(g::GeneralizedSpherical) = constructor_without_checks(typeof(g), -g.pointing, g.r)

##### Base.isapprox #####
Base.isapprox(c1::LocalCartesian, c2::LocalCartesian; kwargs...) = isapprox(raw_svector(c1), raw_svector(c2); kwargs...)
function Base.isapprox(c1::GenericLocalPosition, c2::GenericLocalPosition; kwargs...)
    c1 = convert(LocalCartesian, c1)
    c2 = convert(LocalCartesian, c2)
    isapprox(c1, c2; kwargs...)
end


# GeneralizedSpherical <-> GeneralizedSpherical
function _convert_same(::Type{DST}, src::SRC) where {DST <: GeneralizedSpherical, SRC <: GeneralizedSpherical}
    has_pointingtype(DST) || return src
    P = enforce_numbertype(pointing_type(DST), numbertype(src))
    p = convert(P, src.pointing)
    T = numbertype(P)
    constructor_without_checks(GeneralizedSpherical{T, P}, p, src.r)
end

##### Random.rand #####
# LocalCartesian
# Handled by generic LengthCartesian function in fallbacks.jl

# GeneralizedSpherical
function Random.rand(rng::AbstractRNG, ::SamplerType{G}) where G <: GeneralizedSpherical
    p = rand(rng, pointing_type(G))
    r = 1e3 * ((1 + rand(rng)) * u"m")
    constructor_without_checks(enforce_numbertype(G), p, r)
end

##### Utilities #####
function raw_properties(c::GeneralizedSpherical{<:Any, P}) where P <: AbstractPointing
    p = getfield(c, :pointing)
    r = getfield(c, :r)
    return (; raw_properties(p)..., r)
end

# Custom implementation of change_numbertype for GeneralizedSpherical
function change_numbertype(::Type{T}, g::G) where {T <: AbstractFloat, G <: GeneralizedSpherical} 
    PT = basetype(pointing_type(g)){T}
    convert(GeneralizedSpherical{T, PT}, g)
end


# Check if a potentially abstract subtype of GeneralizedSherical has an associated pointing type
has_pointingtype(::Type{GeneralizedSpherical}) = return false
has_pointingtype(::Type{GeneralizedSpherical{T}}) where {T} = return false
has_pointingtype(::Type{GeneralizedSpherical{T, P}}) where {T, P} = return true

# Returns the pointing type of a GeneralizedSpherical subtype, if it's unique or throw an error otherwise
pointing_type(::Type{GeneralizedSpherical}) = throw(ArgumentError("No pointing type can be uniquely inferred from GeneralizedSpherical"))
pointing_type(::Type{GeneralizedSpherical{T}}) where {T} = throw(ArgumentError("No pointing type can be uniquely inferred from GeneralizedSpherical{$T}"))
pointing_type(::Type{GeneralizedSpherical{T, P}}) where {T, P} = P
pointing_type(g::GeneralizedSpherical) = pointing_type(typeof(g))
for P in (:ThetaPhi, :AzOverEl, :ElOverAz, :AzEl)
    eval(:(has_pointingtype(::Type{GeneralizedSpherical{T, $P{T}} where T}) = return true))
    eval(:(pointing_type(::Type{GeneralizedSpherical{T, $P{T}} where T}) = return $P))
end

#### Custom show methods ####

PlutoShowHelpers.shortname(g::GeneralizedSpherical) = repr(typeof(g))
PlutoShowHelpers.shortname(::Spherical) = "Spherical"
PlutoShowHelpers.shortname(::AzElDistance) = "AzElDistance"

function PlutoShowHelpers.show_namedtuple(g::GeneralizedSpherical) 
    nt1 = show_namedtuple(g.pointing)
    (; nt1..., r = DisplayLength(g.r |> normalize_value))
end