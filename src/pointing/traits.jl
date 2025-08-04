# This function returns the type of the pointing CRS for a given CRS type. It is used to get the type of the pointing CRS from a CRS type.
pointingcrs(P::Type{<:AbstractPointingCRS}) = return P