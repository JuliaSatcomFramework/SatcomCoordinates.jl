function Base.:(-)(c::Coordinate{<:DirectionCosines})
    newtup = map(-, tuplecoords(c))
    return constructor_without_checks(basetype(c), crs(c), newtup)
end
function Base.:(-)(p::Coordinate{<:Union{ElOverAz, AzEl, AzOverEl}})
    (;az, el) = Raw(p)
    if crs(p) isa Union{AzEl, ElOverAz}
        el = -el
    end
    az = az - copysign(π, az)
    constructor_without_checks(basetype(p), crs(p), (az, el))
end
function Base.:(-)(p::Coordinate{<:ThetaPhi})
    (;θ, φ) = Raw(p)
    v = (π - θ, φ - copysign(π, φ))
    constructor_without_checks(basetype(p), crs(p), v)
end


###################################################################
########                  Other Helpers                    ########
###################################################################

# This function returns the type of the pointing CRS for a given CRS type. It is used to get the type of the pointing CRS from a CRS type.
pointingcrs(P::Type{<:AbstractPointingCRS}) = P
pointingcrs(crs::AbstractCRS) = pointingcrs(typeof(crs))


#### Random.rand #####
function rand_tuplecoords(rng::AbstractRNG, ::DirectionCosines, T::Type{<:AbstractFloat})
    tup = ntuple(i -> rand(rng) - .5, 3)
    return map(T, tup ./ hypot(tup...))
end

function rand_tuplecoords(rng::AbstractRNG, crs::UV, T::Type{<:AbstractFloat})
    dc = DirectionCosines(linkedcrs(crs))
    u, v, w = rand_tuplecoords(rng, dc, T)
    return map(T, (u, v))
end

function rand_tuplecoords(rng::AbstractRNG, ::ThetaPhi, T::Type{<:AbstractFloat})
    θ = rand(rng) * π
    φ = rand(rng) * 2π - π
    return map(T, (θ, φ))
end

function rand_tuplecoords(rng::AbstractRNG, ::Union{AzOverEl, ElOverAz, AzEl}, T::Type{<:AbstractFloat})
    az = rand(rng) * 2π - π
    el = rand(rng) * π - π/2
    return map(T, (az, el))
end


#### Custom isapprox between pointing types ####
# All of the isapprox methods will always convert both inputs to 
function raw_isapprox(C::Type{<:AbstractSatcomCoordinate}, crs1::CRS, crs2::CRS, coords1::NTuple{3, <:AbstractFloat}, coords2::NTuple{3, <:AbstractFloat}; kwargs...) where {CRS <: DirectionCosines}
    return isapprox(SVector(coords1), SVector(coords2); kwargs...)
end
function raw_isapprox(C::Type{<:AbstractSatcomCoordinate}, crs1::AbstractPointingCRS{CRS}, crs2::AbstractPointingCRS{CRS}, coords1::NTuple{N, <:AbstractFloat}, coords2::NTuple{M, <:AbstractFloat}; kwargs...) where {CRS <: AbstractCRS, N, M}
    basecartesian = linkedcrs(crs1)
    dc_crs = DirectionCosines(basecartesian)
    coords1 = transform_tuplecoords(dc_crs, crs1, coords1)
    coords2 = transform_tuplecoords(dc_crs, crs2, coords2)
    return raw_isapprox(C, dc_crs, dc_crs, coords1, coords2; kwargs...)
end