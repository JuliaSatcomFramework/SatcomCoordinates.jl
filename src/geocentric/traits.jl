"""
    ecefcrs

CRS Trait function to represent CRSs which are Ellipsoid-Centered-Ellipsoid-Fixed (ECEF).
""" 
ecefcrs(CRS::Type{<:ECEF}) = return CRS

"""
    ecicrs

CRS Trait function to represent CRSs which are Ellipsoid-Centered-Inertial (ECI).
""" 
ecicrs(CRS::Type{<:ECI}) = return CRS

"""
    llacrs

CRS Trait function to represent CRSs which store coordinates in Latitude/Longitude/Altitude (LLA).
""" 
llacrs(CRS::Type{<:LLA}) = return CRS