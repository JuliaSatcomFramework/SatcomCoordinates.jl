###################################################################
########               Constructors/Helpers                ########
###################################################################

# This function is used to wrap angles going beyond the [-180°, 180°] range to provide consistent 2-angle representation of any point on the sphere (and depending on the specific pointing CRS)
wrap_spherical_angles_rad_normalized(az::T, el::T, ::Type{<:Union{AzOverEl, ElOverAz, AzEl}}) where {T <: AbstractFloat} =
    ifelse(
        abs(el) <= π/2,  # Condition
        (az, el), # Azimuth angle is already between -180° and 180° as it's already been normalized
        (az - copysign(π,az), el - copysign(π,el)) # Need to wrap
    )

wrap_spherical_angles_rad_normalized(θ::T, φ::T, ::Type{<:ThetaPhi}) where {T <: AbstractFloat} =
    ifelse(
        θ >= 0,  # Condition
        (θ, φ), # First angle is already between -90° and 90°
        (-θ, φ - copysign(π,φ)) # Need to wrap
    )

function process_unitless_coords(::Type{<:Coordinate}, crs::AbstractPointingCRS, coords::NTuple{2,<:AbstractFloat})
    PT = typeof(crs)
    tup = map(coords) do val
        rem2pi(val, RoundNearest)
    end
    return wrap_spherical_angles_rad_normalized(tup..., PT)
end

const UV_CONSTRUCTOR_TOLERANCE = Ref{Float64}(1e-5)

function process_unitless_coords(::Type{<:Coordinate}, crs::UV, coords::NTuple{2,<:AbstractFloat})
    u, v = coords
    n = u^2 + v^2
    tol = UV_CONSTRUCTOR_TOLERANCE[]
    lim = 1 + tol
    if (n > 1 && n <= lim)
        c = 1 / sqrt(n)
        u *= c
        v *= c
    end
    if (n > lim)
        error("The provided inputs do not satisfy u^2 + v^2 <= 1 + tolerance
    u = $u 
    v = $v 
    u^2 + v^2 = $n
    tolerance = $(tol)")
    end
    return (u, v)
end

function process_unitless_coords(::Type{<:Coordinate}, crs::DirectionCosines, coords::NTuple{3,<:AbstractFloat})
    return Tuple(normalize(SVector(coords)))
end

# This is the default no-arg constructor for any pointing CRS. It falls back to use the `default_wrappedcrs` function to get the default wrapped CRS for the specific CRS type.
function (CRS::Type{<:AbstractPointingCRS})()
    # This is the no-arg constructor, it creates a pointing CRS with the default wrapped CRS
    return CRS(Cartesian())
end