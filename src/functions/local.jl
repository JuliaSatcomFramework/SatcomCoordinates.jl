##### Constructors #####

# LocalCartesian
# Handled by generic LengthCartesian constructor in fallbacks.jl

# GeneralizedSpherical
# Nan constructor
function (::Type{GS})(::Val{NaN}) where GS <: GeneralizedSpherical
    G = enforce_numbertype(GS)
    T = numbertype(G)
    PT = pointing_type(G)
    p = PT(Val{NaN}())
    constructor_without_checks(GeneralizedSpherical{T, PT}, p, to_meters(T(NaN)))
end
# Constructor from pointing and range, with specific numbertype
function GeneralizedSpherical{T}(p::P, r::ValidDistance) where {T <: AbstractFloat, P <: AngularPointing}
    B = basetype(P)
    pc = convert(B{T}, p)
    constructor_without_checks(GeneralizedSpherical{T, typeof(pc)}, p, to_meters(r))
end

# Constructor from pointing and range, with inferred numbertype
function GeneralizedSpherical(p::P, r::ValidDistance) where {P <: AngularPointing} 
    T = default_numbertype(p, r)
    GeneralizedSpherical{T}(p, r)
end

function (::Type{P})(α::ValidAngle, β::ValidAngle, r::ValidDistance) where {P <: GeneralizedSpherical}
    NT = default_numbertype(α, β, r)
    G = enforce_numbertype(P, NT)
    T = numbertype(G)
    PT = enforce_numbertype(pointing_type(P), T)
    p = PT(α, β)
    constructor_without_checks(GeneralizedSpherical{T, PT}, p, to_meters(r))
end

##### Base.getproperty #####
# GenerializedSpherical
function Base.getproperty(g::GeneralizedSpherical, s::Symbol)
    s == :pointing && return getfield(g, :pointing)
    s in (:r, :range, :distance) && return getfield(g, :r)
    return getproperty(getfield(g, :pointing), s)
end

##### convert #####
# LocalCartesian <-> GeneralizedSpherical
function _convert_different(::Type{L}, src::G) where {L <: LocalCartesian, G <: GeneralizedSpherical}
    C = enforce_numbertype(L, src)
    (; pointing, r) = src
    p = convert(PointingVersor, pointing)
    (;x, y, z) = to_svector(p) .* r
    constructor_without_checks(C, x, y, z)
end
function _convert_different(::Type{G}, src::L) where {G <: GeneralizedSpherical, L <: LocalCartesian}
    P = enforce_numbertype(G, src)
    (; x, y, z) = src |> to_svector
    p = PointingVersor(x, y, z)
    r = norm(to_svector(src)) * u"m"
    constructor_without_checks(P, p, r)
end

##### Pointing Inversion #####
Base.:(-)(g::GeneralizedSpherical) = constructor_without_checks(typeof(g), -g.pointing, g.r)

##### Base.isapprox #####
Base.isapprox(c1::LocalCartesian, c2::LocalCartesian; kwargs...) = isapprox(to_svector(c1), to_svector(c2); kwargs...)
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
function raw_nt(g::GeneralizedSpherical)
    pt_nt = @inline raw_nt(getfield(g, :pointing))
    nt = (pt_nt..., r = getfield(g, :r))
    map(normalize_value, nt)
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