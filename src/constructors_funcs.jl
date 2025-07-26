function process_unitless_coords(::Type{P}, crs::AbstractPointingCRS, coords::NTuple{<:Any, T}) where {P <: Pointing, T}
    PT = typeof(crs)
    tup = map(coords) do val
        rem2pi(deg2rad(val), RoundNearest)
    end
    raw = if PT <: UV
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
        (u, v)
    else
        wrap_spherical_angles_rad_normalized(tup..., PT)
    end
    return raw
end

for T in (Vararg{Number, 2}, Point{2, Number})
    @eval function (CRS::Type{<:AbstractPointingCRS})(coords::$T)
        # This is the constructor with coordinates, it creates a pointing CRS with the default wrapped CRS and the provided coordinates
        return CRS(default_wrappedcrs(CRS), coords...)
    end

    @eval function (CRS::Type{<:AbstractPointingCRS})(wrapped_crs::AbstractCRS, coords::$T)
        crs = CRS(wrapped_crs)
        return Pointing(crs, coords)
    end
end
