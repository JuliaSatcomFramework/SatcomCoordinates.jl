##################################################################
########                 Type Definitions                 ########
##################################################################

"""
    Cartesian <: AbstractCartesianCRS

Generic Cartesian CRS, for use in cases that do not require any specific identification of a CRS/Position
"""
struct Cartesian <: AbstractCartesianCRS end

##################################################################
########                 CRS Properties                  #########
##################################################################

# Have cartesian CRSs standard properties and units by default
@define_properties AbstractCartesianCRS [
    x => u"m"
    y => u"m"
    z => u"m"
]