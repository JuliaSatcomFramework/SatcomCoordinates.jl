"""
    Raw{C <: FieldOrCoordinate} <: FieldOrCoordinate

Structure that is only used to wrap a `FieldOrCoordinate` object and allow to access its raw values (i.e. normalized and without units) directly via `Base.getproperty`.

# Example
```julia
using SatcomCoordinates

# Define our custom Cartesian CRS
struct CustomKM <: AbstractCRS end

# We specify that this has x,y,z properties which have default unit of km (i.e. plain numbers are interpreted as km). The raw coordinates (i.e. how they are stored internally in the coordinate instances) are actually floating point values represented in meters (as that is the SI unit for length)
@define_properties CustomKM [
    x => u"km"
    y => u"km"
    z => u"km"
]

# Create a position in the custom CRS at x = 1km, y = 2km, z = 3km
pkm = Position(CartesianKM(), 1,2,3)

# Normal property access 
pkm.x === 1.0u"km" # true

# If you want to directly access the raw unitless data (e.g. inside of hot loops), you can wrap the coordinate in `Raw`
(; y) = Raw(pkm) # This uses the julia desctructuring synthax that relies on `Base.getproperty`

y === 2000.0 # true
```
"""
struct Raw{CRS <: AbstractCRS, C <: FieldOrCoordinate{CRS}} <: FieldOrCoordinate{CRS}
    wrapped::C
end
Raw(c::FieldOrCoordinate{CRS}) where {CRS} = Raw{CRS, typeof(c)}(c)

@inline wrapped(r::Raw) = getfield(r, :wrapped)
@inline Base.propertynames(r::Raw) = propertynames(wrapped(r))
@inline coords(r::Raw) = rawcoords(wrapped(r))
@inline crs(r::Raw) = crs(wrapped(r))

StaticArrays.SVector(r::Raw) = SVector(tuplecoords(wrapped(r)))