#### Traits ####
position_trait(::Type{<:GeneralizedSpherical}) = SphericalPositionTrait()

##### Misc #####
function inner_pointing(g::GeneralizedSpherical{P, T}) where {P <: AngularPointing, T}
    a1, a2, r = raw_svector(g)
    return constructor_without_checks(P{T}, SVector{2, T}(a1, a2))
end

##### Constructors #####

# LocalCartesian
# Handled by generic constructor in fallbacks.jl

# GeneralizedSpherical
function construct_inner_svector(::Type{GeneralizedSpherical{P, T}}, args::Vararg{PS, 3}) where {T <: AbstractFloat, P <: AngularPointing}
    P === basetype(P) || throw(ArgumentError("You can only use `AngularPointing` subtypes without specific numbertype as type parameter `P`, you should use `$(basetype(P))` instead of the provided `$(P)`"))
    a1, a2, r = args
    p = P{T}(a1, a2)
    r = to_meters(r) |> ustrip
    a1, a2 = raw_svector(p)
    return SVector{3, T}(a1, a2, r)
end
# Constructor from pointing and distance
function GeneralizedSpherical(p::P, r::ValidDistance) where P <: AngularPointing 
    a1, a2 = raw_svector(p)
    T = numbertype(P)
    r = to_meters(r) |> ustrip
    constructor_without_checks(GeneralizedSpherical{basetype(P), T}, SVector{3, T}(a1, a2, r))
end



##### Base.getproperty #####
# GenerializedSpherical
properties_names(::Type{<:GeneralizedSpherical{P}}) where P = (properties_names(P)..., :r)

##### convert #####
# LocalCartesian <-> GeneralizedSpherical
function _convert_different(L::Type{<:LocalCartesian}, src::GeneralizedSpherical{P}) where {P <: AngularPointing}
    C = enforce_numbertype(L, src)
    (; r) = raw_properties(src)
    pointing = inner_pointing(src)
    p = convert(PointingVersor, pointing)
    sv = raw_svector(p) .* r
    constructor_without_checks(C, sv)
end
function _convert_different(G::Type{<:GeneralizedSpherical{P}}, src::LocalCartesian) where {P <: AngularPointing}
    GT = enforce_numbertype(G, src)
    T = numbertype(GT)
    src_sv = raw_svector(src)
    r = norm(src_sv)
    src_sv = src_sv ./ r
    pv = constructor_without_checks(PointingVersor{T}, src_sv)
    p = convert(P{T}, pv)
    GeneralizedSpherical(p, r)
end

##### Pointing Inversion #####
Base.:(-)(g::GeneralizedSpherical) = GeneralizedSpherical(-inner_pointing(g), g.r)

##### Base.isapprox #####
Base.isapprox(c1::LocalCartesian, c2::LocalCartesian; kwargs...) = isapprox(raw_svector(c1), raw_svector(c2); kwargs...)
function Base.isapprox(c1::AbstractLocalPosition, c2::AbstractLocalPosition; kwargs...)
    c1 = convert(LocalCartesian, c1)
    c2 = convert(LocalCartesian, c2)
    isapprox(c1, c2; kwargs...)
end


# GeneralizedSpherical <-> GeneralizedSpherical
function _convert_same(DST::Type{<:GeneralizedSpherical}, src::GeneralizedSpherical)
    has_pointingtype(DST) || return src
    GPT = enforce_numbertype(DST, src)
    P = pointing_type(DST)
    T = numbertype(GPT)
    p = convert(P{T}, inner_pointing(src))
    GeneralizedSpherical(p, src.r)
end

##### Random.rand #####
# LocalCartesian
# Handled by generic LengthCartesian function in fallbacks.jl

# GeneralizedSpherical
function Random.rand(rng::AbstractRNG, ::SamplerType{G}) where G <: GeneralizedSpherical
    GT = enforce_numbertype(G)
    T = numbertype(GT)
    P = pointing_type(G)
    p = rand(rng, P{T})
    r = 1e3 * ((1 + rand(rng)))
    GeneralizedSpherical(p, r)
end

# Custom implementation of change_numbertype for GeneralizedSpherical
function change_numbertype(::Type{T}, g::GeneralizedSpherical{P}) where {T <: AbstractFloat, P} 
    sv = raw_svector(g) |> change_numbertype(T)
    GT = GeneralizedSpherical{P, T}
    constructor_without_checks(GT, sv)
end


# Check if a potentially abstract subtype of GeneralizedSherical has an associated pointing type
has_pointingtype(::Type{GeneralizedSpherical}) = return false
has_pointingtype(::Type{<:GeneralizedSpherical{P}}) where {P} = return true

# Returns the pointing type of a GeneralizedSpherical subtype, if it's unique or throw an error otherwise
pointing_type(::Type{GeneralizedSpherical}) = throw(ArgumentError("No pointing type can be uniquely inferred from GeneralizedSpherical"))
pointing_type(::Type{<:GeneralizedSpherical{P}}) where {P} = P

# #### Custom show methods ####

PlutoShowHelpers.shortname(::Spherical) = "Spherical"
PlutoShowHelpers.shortname(::AzElDistance) = "AzElDistance"