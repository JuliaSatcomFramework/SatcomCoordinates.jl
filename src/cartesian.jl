##################################################################
########                 Type Definitions                 ########
##################################################################

"""
    Cartesian <: AbstractCRS

Generic Cartesian CRS, for use in cases that do not require any specific identification of a CRS/Position
"""
struct Cartesian <: AbstractCRS end

##################################################################
########                 CRS Properties                  #########
##################################################################

# Have cartesian CRSs standard properties and units by default
@define_properties AbstractCRS [
    x => u"m"
    y => u"m"
    z => u"m"
]