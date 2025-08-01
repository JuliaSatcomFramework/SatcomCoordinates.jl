"""
    isecefcrs(CRS::Type{<:AbstractCRS})
    isecefcrs(crs::AbstractCRS)

Return `true` if the provided CRS `crs` (or CRS type `CRS`) is an Ellipsoid-Centered-Ellipsoid-Fixed (ECEF) one.

Any CRS which adheres to this trait (i.e. for which `isecefcrs(crs) == true`) must have a valid method for the `frameid` method:
""" 
isecefcrs(obj) = return hascrstrait(isecefcrs, obj)
isecefcrs(::Type{<:AbstractCRS}) = return false

"""
    isecicrs(CRS::Type{<:AbstractCRS})
    isecicrs(crs::AbstractCRS)

Return `true` if the provided CRS `crs` (or CRS type `CRS`) is an Ellipsoid-Centered-Inertial (ECI) one.

Any CRS which adheres to this trait (i.e. for which `isecicrs(crs) == true`) must have a valid method for the `frameid` method:
""" 
isecicrs(obj) = return hascrstrait(isecicrs, obj)
isecicrs(::Type{<:AbstractCRS}) = return false

"""
    isllacrs(CRS::Type{<:AbstractCRS})
    isllacrs(crs::AbstractCRS)

Return `true` if the provided CRS `crs` (or CRS type `CRS`) is a Local Level Angle (LLA) CRS.

Any CRS which adheres to this trait (i.e. for which `isllacrs(crs) == true`) must have `lat` and `lon` as valid property names or aliases and must be based on an ECEF CRS (i.e. it must satisfy `isecefcrs(linkedcrs(lla_crs)) == true`).
"""
isllacrs(obj) = return hascrstrait(isllacrs, obj)
isllacrs(::Type{<:AbstractCRS}) = return false