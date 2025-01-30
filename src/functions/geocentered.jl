# Constructors

## ECI/ECEF
for P in (:ECI, :ECEF)
    # Constructor with specified numbertype
    eval(:(
    function $P{T}(xyz::Vararg{ValidDistance, 3}) where T <: AbstractFloat
        x, y, z = map(to_meters, xyz)
        constructor_without_checks($P{T}, x, y, z)
    end
    ))
    # Function without specified numbertype
    eval(:(
    function $P(xyz::Vararg{ValidDistance, 3})
        NT = promote_type(map(numbertype, xyz)...)
        T = NT <: AbstractFloat ? NT : Float64
        $P{T}(xyz...)
    end
    ))
end

## LLA
function LLA{T}(lat::ValidAngle, lon::ValidAngle, alt::ValidDistance) where T
    lat = to_degrees(lat)
    lon = to_degrees(lon, RoundNearest)
    @assert -90° ≤ lat ≤ 90° "The input latitude must satisfy `lat ∈ [-90°, 90°]`"
    alt = to_meters(alt)
    constructor_without_checks(LLA{T}, lat, lon, alt)
end
function LLA(lat::ValidAngle, lon::ValidAngle, alt::ValidDistance)
    NT = promote_type(map(numbertype, (lat, lon, alt))...)
    T = NT <: AbstractFloat ? NT : Float64
    LLA{T}(lat, lon, alt)
end