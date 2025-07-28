function process_unitless_coords(::Type{<:Coordinate}, crs::AbstractPointingCRS, coords::NTuple{2,T}) where {T}
    PT = typeof(crs)
    tup = map(coords) do val
        rem2pi(val, RoundNearest)
    end
    return wrap_spherical_angles_rad_normalized(tup..., PT)
end

function process_unitless_coords(::Type{<:Coordinate}, crs::UV, coords::NTuple{2,T}) where {T}
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

for T in (Vararg{Number,2}, Point{2,Number})
    @eval function (CRS::Type{<:AbstractPointingCRS})(coords::$T)
        # This is the constructor with coordinates, it creates a pointing CRS with the default wrapped CRS and the provided coordinates
        return CRS(default_wrappedcrs(CRS), coords...)
    end

    @eval function (CRS::Type{<:AbstractPointingCRS})(wrapped_crs::AbstractCRS, coords::$T)
        crs = CRS(wrapped_crs)
        return Pointing(crs, coords)
    end
end

function process_unitless_coords(::Type{P}, crs::DirectionCosines, coords::NTuple{3,T}) where {P<:Pointing,T}
    return coords ./ hypot(coords...)
end
for T in (Vararg{Number,3}, Point{3,Number})
    @eval function (CRS::Type{<:DirectionCosines})(coords::$T)
        # This is the constructor with coordinates, it creates a pointing CRS with the default wrapped CRS and the provided coordinates
        return CRS(default_wrappedcrs(CRS), coords...)
    end

    @eval function (CRS::Type{<:DirectionCosines})(wrapped_crs::AbstractCRS, coords::$T)
        crs = CRS(wrapped_crs)
        return Pointing(crs, coords)
    end
end

### Spherical
function process_unitless_coords(C::Type{<:AbstractSatcomCoordinate}, crs::SphericalCRS, coords::NTuple{3,<:AbstractFloat})
    ptcrs = wrappedcrs(crs)
    pt = process_unitless_coords(Pointing, ptcrs, coords[1:2])
    (pt..., coords[3])
end