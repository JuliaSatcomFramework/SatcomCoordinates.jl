"""
    isecefcrs(CRS::Type{<:AbstractCRS})
    isecefcrs(crs::AbstractCRS)

Return `true` if the provided CRS `crs` (or CRS type `CRS`) is an Ellipsoid-Centered-Ellipsoid-Fixed (ECEF) one.
""" 
isecefcrs(obj) = return hascrstrait(isecefcrs, obj)
isecefcrs(::Type{<:AbstractCRS}) = return false

"""
    isecicrs(CRS::Type{<:AbstractCRS})
    isecicrs(crs::AbstractCRS)

Return `true` if the provided CRS `crs` (or CRS type `CRS`) is an Ellipsoid-Centered-Inertial (ECI) one.
""" 
isecicrs(obj) = return hascrstrait(isecicrs, obj)
isecicrs(::Type{<:AbstractCRS}) = return false

"""
    isllacrs(CRS::Type{<:AbstractCRS})
    isllacrs(crs::AbstractCRS)

Return `true` if the provided CRS `crs` (or CRS type `CRS`) is a Local Level Angle (LLA) CRS.
"""
isllacrs(obj) = return hascrstrait(isllacrs, obj)
isllacrs(::Type{<:AbstractCRS}) = return false
