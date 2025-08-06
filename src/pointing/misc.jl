function raw_negation(::DirectionCosines, tup::NTuple)
    return map(-, tup)
end
function raw_negation(crs::Union{AzEl, ElOverAz, AzOverEl}, tup::NTuple)
    az, el = tup
    if crs isa Union{AzEl, ElOverAz}
        el = -el
    end
    az = az - copysign(π, az)
    return (az, el)
end
function raw_negation(::ThetaPhi, tup::NTuple)
    θ, φ = tup
    return (π - θ, φ - copysign(π, φ))
end


###################################################################
########                  Other Helpers                    ########
###################################################################

#### Random.rand #####
function rand_tuplecoords(rng::AbstractRNG, ::DirectionCosines, T::Type{<:AbstractFloat})
    tup = ntuple(i -> rand(rng) - .5, 3)
    return map(T, _normalize(tup))
end

function rand_tuplecoords(rng::AbstractRNG, crs::UV, T::Type{<:AbstractFloat})
    dc = DirectionCosines(getcrs(linkedcrs, crs))
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
    basecartesian = getcrs(linkedcrs, crs1)
    dc_crs = DirectionCosines(basecartesian)
    coords1 = transform_tuplecoords(dc_crs, crs1, coords1)
    coords2 = transform_tuplecoords(dc_crs, crs2, coords2)
    return raw_isapprox(C, dc_crs, dc_crs, coords1, coords2; kwargs...)
end