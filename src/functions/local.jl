##### Constructors #####

# LocalCartesian
# Handled by generic LengthCartesian constructor in fallbacks.jl

# GeneralizedSpherical
# Constructor from pointing and range, with specific numbertype
function GeneralizedSpherical{T}(p::P, r::ValidDistance) where {T <: AbstractFloat, P <: AngularPointing}
    B = basetype(P)
    pc = convert(B{T}, p)
    constructor_without_checks(GeneralizedSpherical{T, typeof(pc)}, p, to_meters(r))
end

# Constructor from pointing and range, with inferred numbertype
function GeneralizedSpherical(p::P, r::ValidDistance) where {P <: AngularPointing} 
    T = promote_type(map(numbertype, (p, r))...)
    GeneralizedSpherical{T <: AbstractFloat ? T : Float64}(p, r)
end

function (::Type{P})(α::ValidAngle, β::ValidAngle, r::ValidDistance) where {P <: GeneralizedSpherical}
    NT = promote_type(map(numbertype, (α, β, r))...)
    T = NT <: AbstractFloat ? NT : Float64
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


# Check if a potentially abstract subtype of GeneralizedSherical has an associated pointing type
has_pointingtype(::Type{GeneralizedSpherical}) = false
has_pointingtype(::Type{GeneralizedSpherical{T}}) where {T} = false
has_pointingtype(::Type{GeneralizedSpherical{T, P}}) where {T, P} = true

# Returns the pointing type of a GeneralizedSpherical subtype, if it's unique or throw an error otherwise
pointing_type(::Type{GeneralizedSpherical}) = throw(ArgumentError("No pointing type can be uniquely inferred from GeneralizedSpherical"))
pointing_type(::Type{GeneralizedSpherical{T}}) where {T} = throw(ArgumentError("No pointing type can be uniquely inferred from GeneralizedSpherical{$T}"))
pointing_type(::Type{GeneralizedSpherical{T, P}}) where {T, P} = P
pointing_type(::Type{G}) where G <: GeneralizedSpherical = throw(ArgumentError("No pointing type can be uniquely inferred from GeneralizedSpherical"))
pointing_type(g::GeneralizedSpherical) = pointing_type(typeof(g))
for P in (:ThetaPhi, :AzOverEl, :ElOverAz, :AzEl)
    eval(:(has_pointingtype(::Type{GeneralizedSpherical{T, $P{T}} where T}) = true))
    eval(:(pointing_type(::Type{GeneralizedSpherical{T, $P{T}} where T}) = $P))
end
