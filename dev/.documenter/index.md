
# SatcomCoordinates.jl {#SatcomCoordinates.jl}

Documentation for `SatcomCoordinates.jl`.
<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.ForwardOrInverse' href='#SatcomCoordinates.ForwardOrInverse'><span class="jlbinding">SatcomCoordinates.ForwardOrInverse</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
const ForwardOrInverse{F <: AbstractCRSTransform} = Union{F, InverseTransform{<:Any, <:F}}
```


Union representing either a forward or reverse transform of F


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/type_aliases.jl#L20-L24" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.WithNumbertype' href='#SatcomCoordinates.WithNumbertype'><span class="jlbinding">SatcomCoordinates.WithNumbertype</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
const WithNumbertype{T} = Union{AbstractSatcomCoordinate{T}, AbstractCRSTransform{T}}
```


Union representing the types defined and exported by this package, which always have a numbertype as first parameter.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/type_aliases.jl#L27-L31" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.AER' href='#SatcomCoordinates.AER'><span class="jlbinding">SatcomCoordinates.AER</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
struct AER{T} <: AbstractTopocentricPosition{T}
```


Represents a position in the Azimuth-Elevation-Range (AER) coordinate system, which is a local coordinate system centered at a point on or above the surface of an Ellipsoid.  The Elevation and Azimuth angles are always defined w.r.t. the ENU CRS with the same origin. More specifically:

**Properties**
- `az::Deg{T}`: Azimuth angle, defined angle in the XY (North-East) plane from the +Y (North) direction to the object, positive towards +X (East) direction. It is constrained to be in the range `[-180°, 180°]`
  
- `el::Deg{T}`: Elevation angle, defined as the angle between the XY plane and the point being described by the AER coordinates, positive towards +Z (Up) direction. It is constrained to be in the range `[-90°, 90°]`
  
- `r::Met{T}`: Range in meters between the origin of the ENU CRS and the point being described by the AER coordinates.
  

**Basic Constructors**

```
AER(az::ValidAngle, el::ValidAngle, r::ValidDistance)
```


`ValidAngle` is either a Real Number, or a subtype of `Unitful.Angle`. `ValidDistance` is either a Real Number, or a subtype of `Unitful.Length`.

If of the provided argument is `NaN`, the returned `AER` object will contain `NaN` for all fields.

**Fallback constructors**

All subtypes of `P <: AbstractSatcomCoordinate` can also be constructed using a Tuple or SVector as input, which will be `splatted` into the standard constructor for `P`

See also: [`ENU`](/index#SatcomCoordinates.ENU), [`NED`](/index#SatcomCoordinates.NED).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/topocentric.jl#L58-L80" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.AbstractAffineCRSTransform' href='#SatcomCoordinates.AbstractAffineCRSTransform'><span class="jlbinding">SatcomCoordinates.AbstractAffineCRSTransform</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AbstractAffineCRSTransform{T}
```


Abstract type representing an affine transform between two CRSs with numbertype `T`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/abstract_types.jl#L65-L69" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.AbstractCRSTransform' href='#SatcomCoordinates.AbstractCRSTransform'><span class="jlbinding">SatcomCoordinates.AbstractCRSTransform</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AbstractCRSTransform{T}
```


Abstract type representing a coordinate transform between two CRSs with numbertype `T`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/abstract_types.jl#L58-L62" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.AbstractFieldValue' href='#SatcomCoordinates.AbstractFieldValue'><span class="jlbinding">SatcomCoordinates.AbstractFieldValue</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AbstractFieldValue{U, CRS, T}
```


Abstract type representing the value of a physical field expressed in a specific coordinate reference system `CRS`, and whose components have an associated unit `U` and a numbertype `T`.

Concrete implementations of this subtype are expected to have a single inner field `svector` which is a `SVector{N, T}` (`N` being the number of dimensions of the referenced `CRS`) and define the `BasicTypes.constructor_without_checks` method as per other coordinates in order to exploit the convenience functions defined on this abstract type.

An example concrete type representing velocity in a 3D CRS can be implemented as follows (assuming to have `Quantity`, `@u_str` and `dimension` imported from `Unitful`, and `SVector` from StaticArrays):

```julia
const U = typeof(u"m/s")
const D = dimension(u"m/s")

const V{T} = Quantity{T, D, U}

struct VelocityFieldValue{CRS <: AbstractPosition{<:Any, 3}, T} <: AbstractFieldValue{U, CRS, T}
    svector::SVector{3, T}

    BasicTypes.constructor_without_checks(::Type{VelocityFieldValue{CRS, T}}, sv::SVector{3, T}) where {CRS, T} = new{CRS, T}(sv)
end

fv = VelocityFieldValue{ECEF}(1, 2, 3)

@test fv.x == 1u"m/s"
@test fv.y == 2u"m/s"
@test fv.z == 3u"m/s"

@test raw_svector(fv) == SVector{3, Float64}(1, 2, 3)
@test raw_properties(fv) == (x=1, y=2, z=3)
```


**Concrete subtypes**

`SatcomCoordinates.jl` currently does not implement concrete subtypes of `AbstractFieldValue`, but only defines the following methods that work if concrete subtypes are impelemented as in the example above: 
- `raw_svector(::AbstractFieldValue)`: Returns the `svector` field
  
- `raw_properties(::AbstractFieldValue)`: Returns a NamedTuple with the properties of the `svector` field
  
- `properties_names(::Type{<:AbstractFieldValue{U, CRS}})`: Returns the property names of the `CRS` parametric type
  
- Default constructor taking `N` numbers or a Tuple/Svector, with the values interpreted as quantities of unit `U` if not provided directly as quantitites
  
- `ConstructionBase.getproperties(::AbstractFieldValue{U, CRS})`: Returns a NamedTuple with the properties of the field assuming the properties names of `CRS` and returning values with unit `U`. 
  
- `Base.getproperty`: extraction of properties directly from the NamedTuple returned by `ConstructionBase.getproperties`
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/abstract_types.jl#L72-L111" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.AbstractGeocentricPosition' href='#SatcomCoordinates.AbstractGeocentricPosition'><span class="jlbinding">SatcomCoordinates.AbstractGeocentricPosition</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AbstractGeocentricPosition{T} <: AbstractPosition{T, 3}
```


Abstract type representing a position in a geocentric coordinate system.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/abstract_types.jl#L34-L38" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.AbstractLocalPosition' href='#SatcomCoordinates.AbstractLocalPosition'><span class="jlbinding">SatcomCoordinates.AbstractLocalPosition</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AbstractLocalPosition{T} <: AbstractPosition{T, 3}
```


Abstract type representing a position in a local coordinate system.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/abstract_types.jl#L20-L24" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.AbstractPointing' href='#SatcomCoordinates.AbstractPointing'><span class="jlbinding">SatcomCoordinates.AbstractPointing</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AbstractPointing{T} <: AbstractSatcomCoordinate{T, 3}
```


Abstract type representing a pointing direction in 3 dimensions which is backed by fields with shared [`numbertype`](/index#SatcomCoordinates.numbertype) `T`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/abstract_types.jl#L13-L17" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.AbstractPointingOffset' href='#SatcomCoordinates.AbstractPointingOffset'><span class="jlbinding">SatcomCoordinates.AbstractPointingOffset</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AbstractPointingOffset{T} <: AbstractSatcomCoordinate{T, 2}
```


Abstract type representing a pointing offset between two pointing directions.

Currently only has two concrete subtypes: [`UVOffset`](@ref) and [`ThetaPhiOffset`](@ref).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/abstract_types.jl#L49-L55" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.AbstractSatcomCoordinate' href='#SatcomCoordinates.AbstractSatcomCoordinate'><span class="jlbinding">SatcomCoordinates.AbstractSatcomCoordinate</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AbstractSatcomCoordinate{T, N}
```


General abstract type identifying a _coordinate_ with `N` dimensions and an underlying number type `T`. The number type `T` is not necessarily the type of the fields in the type instance, but their underlying real type (this is only different for fields whose types are Unitful quantities, where `numbertype(::Quantity{T}) where T = T`).

::: tip Note

The term _coordinate_ is used here in a loose sense, identifying both position in space as well as pointing directions

:::


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/abstract_types.jl#L1-L8" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.AbstractTopocentricPosition' href='#SatcomCoordinates.AbstractTopocentricPosition'><span class="jlbinding">SatcomCoordinates.AbstractTopocentricPosition</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AbstractTopocentricPosition{T} <: AbstractPosition{T, 3}
```


Abstract type representing a position in a topocentric coordinate system.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/abstract_types.jl#L27-L31" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.AngularPointing' href='#SatcomCoordinates.AngularPointing'><span class="jlbinding">SatcomCoordinates.AngularPointing</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AngularPointing{T}
```


Abstract type representing a pointing direction identified by two angles in degrees, represented with fields of types `Deg{T}`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/abstract_types.jl#L41-L46" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.AzEl' href='#SatcomCoordinates.AzEl'><span class="jlbinding">SatcomCoordinates.AzEl</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AzEl{T} <: AngularPointing{T}
```


Object specifying a pointing direction in &quot;Elevation/Azimuth&quot; coordinates, defined following the convention used for Azimuth-Elevation-Range ([`AER`](/index#SatcomCoordinates.AER)) coordinates used by MATLAB and by this package.

This represents the azimuth/elevation definition often used for describing pointing from a user terminal on ground towards a satellite. They are very similar to the `ElOverAz` definition but with a rotation of the underlying CRS such that elevation is 90° in the direction of the +Z axis and azimuth is computed on the XY plane from the +Y axis towards the +X axis.

Assuming `u`, `v`, and `w` to be direction cosines of the pointing versor `̂p`, their relation with the `El` and `Az` angles is:
- `u = cos(El) * sin(Az)`
  
- `v = cos(El) * cos(Az)`
  
- `w = sin(El)`
  

**Fields**
- `az::Deg{T}: The azimuth angle in degrees, constrained to be in the [-180°, 180°] range.`
  
- `el::Deg{T}: The elevation angle in degrees, constrained to be in the [-90°, 90°] range.`
  

::: tip Note

The fields of `AzEl` objects can also be accessed via `getproperty` using the `azimuth` and `elevation` aliases.

:::

See also: [`ThetaPhi`](/performance#ThetaPhi), [`PointingVersor`](/performance#PointingVersor), [`UV`](/performance#UV), [`ElOverAz`](/performance#ElOverAz), [`AzOverEl`](/performance#AzOverEl)


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/pointing.jl#L163-L183" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.AzElDistance' href='#SatcomCoordinates.AzElDistance'><span class="jlbinding">SatcomCoordinates.AzElDistance</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
const AzElDistance{T} = GeneralizedSpherical{AzEl, T}
```


Type representing a position w.r.t. a local CRS in Azimuth, Elevation and Range coordinates. The difference between `AzElDistance` and [`AER`](/index#SatcomCoordinates.AER) is that `AER` is a always referred to the ENU CRS, while `AzElDistance` is for a generic local CRS.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/type_aliases.jl#L9-L14" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.AzOverEl' href='#SatcomCoordinates.AzOverEl'><span class="jlbinding">SatcomCoordinates.AzOverEl</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AzOverEl{T} <: AngularPointing{T}
```


Object specifying a pointing direction in &quot;Azimuth over Elevation&quot; coordinates, which specify the elevation and azimuth angles that needs to be fed to an azimuth-over-elevation positioner for pointing to a target towards the pointing direction ̂p.

Following the convention used in most Antenna-related literature, the elevation and azimuth are 0° in the direction of the +Z axis of the reference frame.

Assuming `u`, `v`, and `w` to be direction cosines of the pointing versor `̂p`, their relation with the `Az` and `El` angles is:
- `u = -sin(Az)`
  
- `v = cos(Az) * sin(El)`
  
- `w = cos(Az) * cos(El)`
  

::: tip Note

The equations above are used to represent the &quot;Azimuth over Elevation&quot; coordinates in GRASP. Some textbooks, however, use the opposite convention, meaning that the same equations (with a possible flip in the az/u sign) are used to describe an &quot;Elevation over Azimuth&quot; coordinate system. This is for example the case in the book _&quot;Theory and Practice of Modern Antenna Range Measurements&quot;_ by Clive Parini et al.

:::

**Properties**
- `az::Deg{T}: The azimuth angle in degrees, constrained to be in the [-180°, 180°] range.`
  
- `el::Deg{T}: The elevation angle in degrees, constrained to be in the [-90°, 90°] range.`
  

::: tip Note

The fields of `AzOverEl` objects can also be accessed via `getproperty` using the `azimuth` and `elevation` aliases.

:::


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/pointing.jl#L104-L125" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.BasicCRSTransform' href='#SatcomCoordinates.BasicCRSTransform'><span class="jlbinding">SatcomCoordinates.BasicCRSTransform</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
BasicCRSTransform{T, R <: Union{CRSRotation{T}, Identity}, O <: AbstractPosition{T, 3}} <: AbstractCRSTransform{T}
```


A type representing a basic transformation (rotation + translation).

**Fields:**
- `rotation::R`: The rotation of the transformation.
  
- `origin::O`: The origin of the transformation.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/transforms.jl#L21-L29" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.CRSRotation' href='#SatcomCoordinates.CRSRotation'><span class="jlbinding">SatcomCoordinates.CRSRotation</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
CRSRotation{T, R <: StaticMatrix{T, 3, 3}} <: AbstractCRSRotation{T}
```


A type representing a basic rotation of a coordinate system.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/transforms.jl#L12-L16" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.ECEF' href='#SatcomCoordinates.ECEF'><span class="jlbinding">SatcomCoordinates.ECEF</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
struct ECEF{T} <: AbstractGeocentricPosition{T}
```


Represents a position in the Earth-Centered, Earth-Fixed (ECEF) coordinate system (or generically for other planets, Ellipsoid-Centered, Ellipsoid-Fixed).

**Properties**
- `x::Met{T}`: X-coordinate in meters
  
- `y::Met{T}`: Y-coordinate in meters
  
- `z::Met{T}`: Z-coordinate in meters
  

**Basic Constructors**

```
ECEF(x::ValidDistance, y::ValidDistance, z::ValidDistance)
```


`ValidDistance` is either a Real Number, or a subtype of `Unitful.Length`.

If of the provided argument is `NaN`, the returned `ECEF` object will contain `NaN` for all fields.

**Fallback constructors**

All subtypes of `P <: AbstractSatcomCoordinate` can also be constructed using a Tuple or SVector as input, which will be `splatted` into the standard constructor for `P`

See also: [`ECI`](/performance#ECI), [`LLA`](/performance#LLA).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/geocentric.jl#L1-L22" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.ECI' href='#SatcomCoordinates.ECI'><span class="jlbinding">SatcomCoordinates.ECI</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
struct ECI{T} <: AbstractGeocentricPosition{T}
```


Represents a position in the Earth-Centered, Inertial (ECI) coordinate system (or generically for other planets, Ellipsoid-Centered, Inertial).

**Properties**
- `x::Met{T}`: X-coordinate in meters
  
- `y::Met{T}`: Y-coordinate in meters
  
- `z::Met{T}`: Z-coordinate in meters
  

**Basic Constructors**

```
ECI(x::ValidDistance, y::ValidDistance, z::ValidDistance)
```


`ValidDistance` is either a Real Number, or a subtype of `Unitful.Length`.

If of the provided argument is `NaN`, the returned `ECI` object will contain `NaN` for all fields.

**Fallback constructors**

All subtypes of `P <: AbstractSatcomCoordinate` can also be constructed using a Tuple or SVector as input, which will be `splatted` into the standard constructor for `P`

See also: [`ECEF`](/performance#ECEF), [`LLA`](/performance#LLA).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/geocentric.jl#L29-L50" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.ENU' href='#SatcomCoordinates.ENU'><span class="jlbinding">SatcomCoordinates.ENU</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
struct ENU{T} <: AbstractTopocentricPosition{T}
```


Represents a position in the East-North-Up (ENU) coordinate system, which is a local coordinate system centered at a point on or above the surface of an Ellipsoid.  The direction of the ENU axes is uniquely determined by the latitude, longitude, and altitude of the point w.r.t. the referenced ellipsoid.

**Properties**
- `x::Met{T}`: X-coordinate in meters
  
- `y::Met{T}`: Y-coordinate in meters
  
- `z::Met{T}`: Z-coordinate in meters
  

**Basic Constructors**

```
ENU(x::ValidDistance, y::ValidDistance, z::ValidDistance)
```


`ValidDistance` is either a Real Number, or a subtype of `Unitful.Length`.

If of the provided argument is `NaN`, the returned `ENU` object will contain `NaN` for all fields.

**Fallback constructors**

All subtypes of `P <: AbstractSatcomCoordinate` can also be constructed using a Tuple or SVector as input, which will be `splatted` into the standard constructor for `P`

See also: [`NED`](/index#SatcomCoordinates.NED), [`AER`](/index#SatcomCoordinates.AER).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/topocentric.jl#L1-L23" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.ElOverAz' href='#SatcomCoordinates.ElOverAz'><span class="jlbinding">SatcomCoordinates.ElOverAz</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
ElOverAz{T} <: AngularPointing{T}
```


Object specifying a pointing direction in &quot;Elevation over Azimuth&quot; coordinates, which specify the azimuth and elevation angles that needs to be fed to an elevation-over-azimuth positioner for pointing to a target towards the pointing direction ̂p.

Following the convention used in most Antenna-related literature, the elevation and azimuth are 0° in the direction of the +Z axis of the reference frame.

Assuming `u`, `v`, and `w` to be direction cosines of the pointing versor `̂p`, their relation with the `El` and `Az` angles is:
- `u = -sin(Az) * cos(El)`
  
- `v = sin(El)`
  
- `w = cos(Az) * cos(El)`
  

::: tip Note

The equations above are used to represent the &quot;Elevation over Azimuth&quot; coordinates in GRASP. Some textbooks, however, use the opposite convention, meaning that the same equations (with sometimes an additional flip in the az/u sign) are used to describe an &quot;Azimuth over Elevation&quot; coordinate system. This is for example the case in the book _&quot;Theory and Practice of Modern Antenna Range Measurements&quot;_ by Clive Parini et al.

:::

**Fields**
- `az::Deg{T}: The azimuth angle in degrees, constrained to be in the [-180°, 180°] range.`
  
- `el::Deg{T}: The elevation angle in degrees, constrained to be in the [-90°, 90°] range.`
  

::: tip Note

The fields of `ElOverAz` objects can also be accessed via `getproperty` using the `azimuth` and `elevation` aliases.

:::

See also: [`AzOverEl`](/performance#AzOverEl), [`ThetaPhi`](/performance#ThetaPhi), [`PointingVersor`](/performance#PointingVersor), [`UV`](/performance#UV)


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/pointing.jl#L133-L156" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.GeneralizedSpherical' href='#SatcomCoordinates.GeneralizedSpherical'><span class="jlbinding">SatcomCoordinates.GeneralizedSpherical</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
struct GeneralizedSpherical{T, P <: AngularPointing} <: AbstractPosition{T, 3}
```


Represents a position in a local CRS, defined by an angular pointing direction and a distance.

::: tip Note

The parameter `P` should not be a concrete type of angular pointing but a basic subtype without the `numbertype` parameter, e.g. `AzEl` instead of `AzEl{Float64}`.

:::

**Properties**
- `angle1::Deg{T}`: First angle of the referenced angular pointing CRS `P`. The name of the property is actually not `angle1` but will be the first property name of objects of type `P`
  
- `angle2::Deg{T}`: Second angle of the referenced angular pointing CRS `P`. The name of the property is actually not `angle2` but will be the second property name of objects of type `P`
  
- `r::Met{T}`: The distance of the object from the origin of the CRS
  

**Basic Constructors**

```
GeneralizedSpherical(pointing::AngularPointing, r::ValidDistance)
GeneralizedSpherical{P[, T]}(a1::ValidAngle, a2::ValidAngle, r::ValidDistance)
```


`ValidDistance` is either a Real Number, or a subtype of `Unitful.Length`.

If of the provided argument is `NaN`, the returned `PointingAndDistance` object will contain `NaN` for all fields.

See also: [`Spherical`](/index#SatcomCoordinates.Spherical), [`AzElDistance`](/index#SatcomCoordinates.AzElDistance), [`LocalCartesian`](/index#SatcomCoordinates.LocalCartesian).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/local.jl#L30-L51" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.InverseTransform' href='#SatcomCoordinates.InverseTransform'><span class="jlbinding">SatcomCoordinates.InverseTransform</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
InverseTransform{T, F <: AbstractCRSTransform{T}} <: AbstractCRSTransform{T}
```


A type representing an inverse of an [`AbstractCRSTransform`](/index#SatcomCoordinates.AbstractCRSTransform).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/transforms.jl#L1-L5" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.LLA' href='#SatcomCoordinates.LLA'><span class="jlbinding">SatcomCoordinates.LLA</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
struct LLA{T} <: AbstractGeocentricPosition{T}
```


Identify a point on or above earth using geodetic coordinates

**Properties**
- `lat::Deg{T}`: Latitude of the point in degrees [-90°, 90°]
  
- `lon::Deg{T}`: Longitude of the point in degrees [-180°, 180°]
  
- `alt::Met{T}`: Altitude of the point above the reference ellipsoid
  

**Basic Constructors**

```
LLA(lat::ValidAngle,lon::ValidAngle,alt::ValidDistance)
LLA(lat::ValidAngle,lon::ValidAngle) # Defaults to 0m altitude
```


`ValidAngle` is a either a Real number or a `Unitful.Quantity` of unit either `u"rad"` or `u"°"`.

`ValidDistance` is either a Real Number, or a subtype of `Unitful.Length`.

If of the provided argument is `NaN`, the returned `LLA` object will contain `NaN` for all fields.

**Fallback constructors**

All subtypes of `P <: AbstractSatcomCoordinate` can also be constructed using a Tuple or SVector as input, which will be `splatted` into the standard constructor for `P`

See also: [`ECEF`](/performance#ECEF), [`ECI`](/performance#ECI).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/geocentric.jl#L57-L82" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.LocalCartesian' href='#SatcomCoordinates.LocalCartesian'><span class="jlbinding">SatcomCoordinates.LocalCartesian</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
struct LocalCartesian{T} <: AbstractLocalPosition{T, 3}
```


Represents a position in a generic local CRS. 

**Properties**
- `x::Met{T}`: X-coordinate in meters
  
- `y::Met{T}`: Y-coordinate in meters
  
- `z::Met{T}`: Z-coordinate in meters
  

**Basic Constructors**

```
LocalCartesian(x::ValidDistance, y::ValidDistance, z::ValidDistance)
```


`ValidDistance` is either a Real Number, or a subtype of `Unitful.Length`.

If of the provided argument is `NaN`, the returned `LocalCartesian` object will contain `NaN` for all fields.

**Fallback constructors**

All subtypes of `P <: AbstractSatcomCoordinate` can also be constructed using a Tuple or SVector as input, which will be `splatted` into the standard constructor for `P`

See also: [`GeneralizedSpherical`](/index#SatcomCoordinates.GeneralizedSpherical).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/local.jl#L1-L22" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.NED' href='#SatcomCoordinates.NED'><span class="jlbinding">SatcomCoordinates.NED</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
struct NED{T} <: AbstractTopocentricPosition{T}
```


Represents a position in the North-East-Down (NED) coordinate system, which is a local coordinate system centered at a point on or above the surface of an Ellipsoid.  The direction of the NED axes is uniquely determined by the latitude, longitude, and altitude of the point w.r.t. the referenced ellipsoid.

**Properties**
- `x::Met{T}`: X-coordinate in meters
  
- `y::Met{T}`: Y-coordinate in meters
  
- `z::Met{T}`: Z-coordinate in meters
  

**Basic Constructors**

```
NED(x::ValidDistance, y::ValidDistance, z::ValidDistance)
```


`ValidDistance` is either a Real Number, or a subtype of `Unitful.Length`.

If of the provided argument is `NaN`, the returned `NED` object will contain `NaN` for all fields.

**Fallback constructors**

All subtypes of `P <: AbstractSatcomCoordinate` can also be constructed using a Tuple or SVector as input, which will be `splatted` into the standard constructor for `P`

See also: [`ENU`](/index#SatcomCoordinates.ENU), [`AER`](/index#SatcomCoordinates.AER).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/topocentric.jl#L30-L52" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.PointingOffset' href='#SatcomCoordinates.PointingOffset'><span class="jlbinding">SatcomCoordinates.PointingOffset</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
struct PointingOffset{P, T} <: AbstractPointingOffset{T}
```


Type used to describe an offset between two pointing directions.

::: tip Note

The `P` parameter must be a subtype of `Union{UV, AngularPointing}` but must be the basic pointing type without specific numbertype (e.g. `UV` rather than `UV{Float64}`) as the numbertype is already tracked by the `T` parameter within the `PointingOffset` type.

:::


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/pointing_offsets.jl#L1-L8" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.PointingVersor' href='#SatcomCoordinates.PointingVersor'><span class="jlbinding">SatcomCoordinates.PointingVersor</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
PointingVersor{T} <: AbstractPointing{T}
```


A unit vector (versor) representing a pointing direction in 3D space. Its components are the `x`, `y`, and `z` components of the unit vector and can also be seen as the `u`, `v`, and `w` direction cosines of the direction identified by the `PointingVersor` instance.

**Properties**
- `x::T`: The component along the X axis of the corresponding reference frame. Can also be accessed with the `u` property name.
  
- `y::T`: The component along the Y axis of the corresponding reference frame. Can also be accessed with the `v` property name.
  
- `z::T`: The component along the Z axis of the corresponding reference frame. Can also be accessed with the `w` property name.
  

See also: [`UV`](/performance#UV), [`ThetaPhi`](/performance#ThetaPhi), [`AzOverEl`](/performance#AzOverEl), [`ElOverAz`](/performance#ElOverAz)


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/pointing.jl#L1-L15" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.Spherical' href='#SatcomCoordinates.Spherical'><span class="jlbinding">SatcomCoordinates.Spherical</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
const Spherical{T} = GeneralizedSpherical{ThetaPhi, T}
```


Type representing a position in ISO/Physics spherical coordinates


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/type_aliases.jl#L2-L6" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.ThetaPhi' href='#SatcomCoordinates.ThetaPhi'><span class="jlbinding">SatcomCoordinates.ThetaPhi</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
ThetaPhi{T} <: AngularPointing{T}
```


An object specifying a pointing direction in ThetaPhi coordinates, defined as the θ and φ in the (ISO/Physics definition) [spherical coordinates representation](https://en.wikipedia.org/wiki/Spherical_coordinate_system) 

Assuming `u`, `v`, and `w` to be direction cosines of the pointing versor `̂p`, their relation with the `θ` and `φ` angles is:
- `u = sin(θ) * cos(φ)`
  
- `v = sin(θ) * sin(φ)`
  
- `w = cos(θ)`
  

**Properties**
- `θ::Deg{T}`: The so-called `polar angle`, representing the angle between the `Z` axis and the `XY` plane of the reference frame. It is always normalized to fall within the [-90°, 90°] range.
  
- `φ::Deg{T}`: The so-called `azimuth angle`, representing the angle between the `y` and `x` component of the pointing direction. It is always normalized to fall within the [-180°, 180°] range.
  

While the field name use the greek letters, the specific fields of an arbitrary `ThetaPhi` object `tp` can be accessed with alternative symbols:
- `tp.θ`, `tp.theta` and `tp.t` can be used to access the `θ` field
  
- `tp.φ`, `tp.ϕ`, `tp.phi` and `tp.p` can be used to access the `φ` field
  

**Basic Constructors**

```
ThetaPhi(θ,φ)
```


The basic constructor takes 2 separate numbers `θ`, `φ` and instantiate the object.
MarkdownAST.LineBreak()

**Provided inputs are intepreted as degrees if not provided using angular quantities from Unitful.** If either of the inputs is `NaN`, the returned `ThetaPhi` object will contain `NaN` for both fields.

```
ThetaPhi(tp)
```


The `ThetaPhi` struct can be created using any 2-element Tuple or Vector/StaticVector as input, which will internally call the 2-arguments constructor.

See also: [`PointingVersor`](/performance#PointingVersor), [`UV`](/performance#UV)


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/pointing.jl#L62-L96" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.UV' href='#SatcomCoordinates.UV'><span class="jlbinding">SatcomCoordinates.UV</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
UV{T} <: AbstractPointing{T}
```


Specify a pointing direction in UV coordinates, which are equivalent to the direction cosines with respect to the `X` and `Y` axis of the reference frame. They can also be related to the spherical coordinates (ISO/Physics) [spherical coordinates representation](https://en.wikipedia.org/wiki/Spherical_coordinate_system) by the following equations:
- `u = sin(θ) * cos(φ)`
  
- `v = sin(θ) * sin(φ)`
  

::: tip Note

UV coordinates can only be used to represent pointing direction in the half-hemisphere containing the cartesian +Z axis.

:::

::: tip Note

The inputs values must also satisfy `u^2 + v^2 <= 1 + SatcomCoordinates.UV_CONSTRUCTOR_TOLERANCE[]` or an error will be thrown. The `SatcomCoordinates.UV_CONSTRUCTOR_TOLERANCE` is a `Ref{Float64}` which defaults to 1e-5 (In case `u^2 + v^2 > 1` the inputs are normalized to ensure `u^2 + v^2 = 1`).

:::

**Properties**
- `u::T`
  
- `v::T`
  

**Basic Constructors**

```
UV{T}(u,v)
```


The basic constructor takes 2 separate numbers `u`, `v` and instantiate the object assuming that `u^2 + v^2 <= 1` (condition for valid UV pointing), throwing an error otherwise.
MarkdownAST.LineBreak()

If either of the inputs is `NaN`, the returned `UV` object will contain `NaN` for both fields.

```
UV{T}(uv)
```


The `UV{T}` can be created using any 2-element Tuple or StaticVector as input, which will internally call the 2-arguments constructor.

See also: [`PointingVersor`](/performance#PointingVersor), [`ThetaPhi`](/performance#ThetaPhi)


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/types/pointing.jl#L23-L54" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.add_angular_offset-Union{Tuple{P}, Tuple{O}, Tuple{Type{O}, P, ThetaPhi}} where {O<:AbstractPointing, P<:AbstractPointing}' href='#SatcomCoordinates.add_angular_offset-Union{Tuple{P}, Tuple{O}, Tuple{Type{O}, P, ThetaPhi}} where {O<:AbstractPointing, P<:AbstractPointing}'><span class="jlbinding">SatcomCoordinates.add_angular_offset</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
p = add_angular_offset(p₀::AbstractPointing, offset_angles::Union{ThetaPhi, ThetaPhiOffset})
p = add_angular_offset(p₀::PointingType, θ::ValidAngle, φ::ValidAngle = 0.0)
p = add_angular_offset(output_type, p₀, args...)
```


Compute the resulting pointing direction `p` obtained by adding an angular offset expressed as θ and φ angles (following the ISO/Physics convention for spherical coordinates) [deg] to the starting position identified by `p₀`.

The input starting position `p₀` must be any subtype of `AbstractPointing` The input `offset_angles` can be provided as an instance of one of the following types:
- `ThetaPhi`
  
- `ThetaPhiOffset`
  

and is converted to `ThetaPhiOffset` internally, with non-unitful values being interpreted as angles in degrees.

The output is of type `output_type` if provided or of the same type as `p₀` otherwise.

**Note**

If `output_type` is `UV`, the function will throw an error if the final pointing direction is located behind the viewer as the output in UV would be ambiguous. This is not the case for other subtypes of `AbstractPointing` so an explicit output type (different from `UV`) should be provided if the target is expected to be behind the viewer.

The offset angles can also be provided separately as 2nd and 3rd argument (optional, defaults to 0.0) to the function using the second method signature. In this case, the inputs are treated as angles in degrees unless explicitly provided using quantitites with `°` unit from the Unitful package.

This function performs the inverse operation of [`get_angular_offset`](/index#SatcomCoordinates.get_angular_offset-Tuple{AbstractPointing,%20AbstractPointing}) so the following code should return true

```julia
using SatcomCoordinates
uv1 = UV(.3,.4)
uv2 = UV(-.2,.5)
offset = get_angular_offset(uv1, uv2)
p = add_angular_offset(uv1, offset)
p ≈ uv2
```


See also: [`get_angular_offset`](/index#SatcomCoordinates.get_angular_offset-Tuple{AbstractPointing,%20AbstractPointing}), [`get_angular_distance`](/index#SatcomCoordinates.get_angular_distance-Tuple{AbstractPointing,%20AbstractPointing}), [`ThetaPhi`](/performance#ThetaPhi), [`UV`](/performance#UV)


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/functions/pointing_offsets.jl#L158-L196" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.angle_offset_rotation-Tuple{Unitful.Quantity{T, NoDims, Unitful.FreeUnits{°,, NoDims, nothing}} where T, Unitful.Quantity{T, NoDims, Unitful.FreeUnits{°,, NoDims, nothing}} where T}' href='#SatcomCoordinates.angle_offset_rotation-Tuple{Unitful.Quantity{T, NoDims, Unitful.FreeUnits{°,, NoDims, nothing}} where T, Unitful.Quantity{T, NoDims, Unitful.FreeUnits{°,, NoDims, nothing}} where T}'><span class="jlbinding">SatcomCoordinates.angle_offset_rotation</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
angle_offset_rotation(θ, φ)
```


Compute the rotation matrix to find offset points following the procedure in this stackexchnge answer: https://math.stackexchange.com/questions/4343044/rotate-vector-by-a-random-little-amount


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/functions/pointing_offsets.jl#L69-L75" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.change_numbertype' href='#SatcomCoordinates.change_numbertype'><span class="jlbinding">SatcomCoordinates.change_numbertype</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
change_numbertype(T::Type, x)
```


Functions that change the underlying numbertype of the provided object `x` to the first argument `T`.

It has a fallback default implementation for types defined within this package which calls `convert` on the provided object `x` to the type `basetype(x){T}`.

See also [`numbertype`](/index#SatcomCoordinates.numbertype), [`enforce_numbertype`](/index#SatcomCoordinates.enforce_numbertype), [`has_numbertype`](/index#SatcomCoordinates.has_numbertype), [`default_numbertype`](/index#SatcomCoordinates.default_numbertype-Union{NTuple{N,%20Any},%20Tuple{N}}%20where%20N)


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/utils.jl#L45-L53" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.default_numbertype-Union{NTuple{N, Any}, Tuple{N}} where N' href='#SatcomCoordinates.default_numbertype-Union{NTuple{N, Any}, Tuple{N}} where N'><span class="jlbinding">SatcomCoordinates.default_numbertype</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
default_numbertype(args...)
```


Function that returns the common valid numbertype among the arguments provided as input. It finds the common numbertype via `promote_type` and either return that (if it&#39;s a subtype of `AbstractFloat`) or `Float64` if it&#39;s not.

This function is useful to automatically extract from inputs the `numbertype` to use in constructors.

See also [`numbertype`](/index#SatcomCoordinates.numbertype), [`enforce_numbertype`](/index#SatcomCoordinates.enforce_numbertype), [`has_numbertype`](/index#SatcomCoordinates.has_numbertype), [`change_numbertype`](/index#SatcomCoordinates.change_numbertype)


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/utils.jl#L56-L64" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.enforce_numbertype' href='#SatcomCoordinates.enforce_numbertype'><span class="jlbinding">SatcomCoordinates.enforce_numbertype</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
enforce_numbertype(input_type, [default_numbertype]) where {C <: Union{AbstractSatcomCoordinate, AbstractCRSTransform}}
```


Function that takes as input a type and returns a potentialy more specialized subtype of the input type with the numbertype parameter set if not specified in `input_type`. Optionally, this function accepts a secon type (or value) as argument and infers the numbertype to set as default (if not alredy present). The default numbertype when the function is called with 1-argument is `Float64`.

**Examples**

```julia
enforce_numbertype(UV) == UV{Float64} # Provide a default as not present in input type
enforce_numbertype(UV{Float32}) == UV{Float32} # Returns the same input type as it already has a numbertype
enforce_numbertype(UV, Float32) == UV{Float32} # Provide a custom default as not present in input type
enforce_numbertype(UV, 1) == UV{Int64} # Provide a custom default as not present in input type
```


See also [`numbertype`](/index#SatcomCoordinates.numbertype), [`enforce_numbertype`](/index#SatcomCoordinates.enforce_numbertype), [`has_numbertype`](/index#SatcomCoordinates.has_numbertype), [`default_numbertype`](/index#SatcomCoordinates.default_numbertype-Union{NTuple{N,%20Any},%20Tuple{N}}%20where%20N)


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/utils.jl#L27-L42" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.get_angular_distance-Tuple{AbstractPointing, AbstractPointing}' href='#SatcomCoordinates.get_angular_distance-Tuple{AbstractPointing, AbstractPointing}'><span class="jlbinding">SatcomCoordinates.get_angular_distance</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
get_angular_distance(p₁::AbstractPointing, p₂::AbstractPointing)
```


Compute the angular distance [°] between the target pointing direction `p₂` and the starting pointing direction `p₁`. 

**Note**

This function&#39;s output should be approximately equivalent to the θ (theta) component of [`get_angular_offset`](/index#SatcomCoordinates.get_angular_offset-Tuple{AbstractPointing,%20AbstractPointing}) but has a faster implementation.  Use this in case the φ (phi) component is not required and speed is important.  The following code should evaluate to true

```julia
using SatcomCoordinates
uv1 = UV(.3,.4)
uv2 = UV(-.2,.5)
offset = get_angular_offset(uv1, uv2)
Δθ = get_angular_distance(uv1, uv2)
offset.theta ≈ Δθ
```


See also: [`add_angular_offset`](/index#SatcomCoordinates.add_angular_offset-Union{Tuple{P},%20Tuple{O},%20Tuple{Type{O},%20P,%20ThetaPhi}}%20where%20{O<:AbstractPointing,%20P<:AbstractPointing}), [`get_angular_offset`](/index#SatcomCoordinates.get_angular_offset-Tuple{AbstractPointing,%20AbstractPointing})


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/functions/pointing_offsets.jl#L41-L62" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.get_angular_offset-Tuple{AbstractPointing, AbstractPointing}' href='#SatcomCoordinates.get_angular_offset-Tuple{AbstractPointing, AbstractPointing}'><span class="jlbinding">SatcomCoordinates.get_angular_offset</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
offset = get_angular_offset(p₁::AbstractPointing, p₂::AbstractPointing)::ThetaPhiOffset
```


Compute the angular offset required to reach the target pointing direction `p₂` from starting pointing direction `p₁`.  The two input pointings can be of any valid `AbstractPointing` type.

The output is of type `ThetaPhiOffset`

**Note**

This function performs the inverse operation of [`add_angular_offset`](/index#SatcomCoordinates.add_angular_offset-Union{Tuple{P},%20Tuple{O},%20Tuple{Type{O},%20P,%20ThetaPhi}}%20where%20{O<:AbstractPointing,%20P<:AbstractPointing}) so the following code should return true

```julia
using ReferenceViews
uv1 = UV(.3,.4)
uv2 = UV(-.2,.5)
offset = get_angular_offset(uv1, uv2)
p = add_angular_offset(uv1, offset)
p ≈ uv2
```


Check out [`get_angular_distance`](/index#SatcomCoordinates.get_angular_distance-Tuple{AbstractPointing,%20AbstractPointing}) for a slightly faster implementation in case you only require the angular distance rather than the 2D offset.

See also: [`add_angular_offset`](/index#SatcomCoordinates.add_angular_offset-Union{Tuple{P},%20Tuple{O},%20Tuple{Type{O},%20P,%20ThetaPhi}}%20where%20{O<:AbstractPointing,%20P<:AbstractPointing})


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/functions/pointing_offsets.jl#L118-L143" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.has_numbertype' href='#SatcomCoordinates.has_numbertype'><span class="jlbinding">SatcomCoordinates.has_numbertype</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
has_numbertype(T::Type)
has_numbertype(::T)
```


This function shall return `true` if the provided type `T` or object of type `T` has an associated numbertype.

This function will return `false` for types defined within this package that do not have the numbertype parameter specified (type `T` is thus a `UnionAll` on the numbertype parameter).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/utils.jl#L17-L24" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.numbertype' href='#SatcomCoordinates.numbertype'><span class="jlbinding">SatcomCoordinates.numbertype</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
numbertype(T::Type)
numbertype(::T)
```


This function shall return the underlying numbertype of the provided Type or object.

The concept of numbertype is defined here as the subtype of `Real` which is used to represent the numerical values in the object&#39;s field. It is not directly the type of the fields, mainly as we consider fields of type `Unitul.Quantity{T}` to have numbertype `T`.

All the types defined in this package have an assciated parametric numbertype as first parameter.

See also [`enforce_numbertype`](/index#SatcomCoordinates.enforce_numbertype), [`change_numbertype`](/index#SatcomCoordinates.change_numbertype), [`has_numbertype`](/index#SatcomCoordinates.has_numbertype), [`default_numbertype`](/index#SatcomCoordinates.default_numbertype-Union{NTuple{N,%20Any},%20Tuple{N}}%20where%20N)


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/utils.jl#L2-L14" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.origin-Tuple{SatcomCoordinates.AbstractAffineCRSTransform}' href='#SatcomCoordinates.origin-Tuple{SatcomCoordinates.AbstractAffineCRSTransform}'><span class="jlbinding">SatcomCoordinates.origin</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
origin(t::AbstractAffineCRSTransform)
```


This function should return an object which is subtype of `CartesianPosition` and represents the origin of the starting CRS in the target CRS.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/functions/transforms.jl#L14-L18" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.raw_properties-Tuple{AbstractSatcomCoordinate}' href='#SatcomCoordinates.raw_properties-Tuple{AbstractSatcomCoordinate}'><span class="jlbinding">SatcomCoordinates.raw_properties</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
raw_properties(coords::AbstractSatcomCoordinate)
```


Generate a NamedTuple starting from the raw `SVector` holding the coords data and assigning a label to each valid property of the coordinate (as defined by the `Base.propertynames(coords)` function).

See also [`raw_svector`](/index#SatcomCoordinates.raw_svector-Tuple{AbstractSatcomCoordinate})


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/utils.jl#L82-L87" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.raw_svector-Tuple{AbstractSatcomCoordinate}' href='#SatcomCoordinates.raw_svector-Tuple{AbstractSatcomCoordinate}'><span class="jlbinding">SatcomCoordinates.raw_svector</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
raw_svector(coord::AbstractSatcomCoordinate)
```


Extracts the raw `SVector` storing the data for the provided coordinate. This assumes that `coord` has a field called `svector` and just calls `getfield(coord, :svector)`.

Concrete subtypes that do not follow this convention should overload this function.

See also [`raw_properties`](/index#SatcomCoordinates.raw_properties-Tuple{AbstractSatcomCoordinate})


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/utils.jl#L70-L79" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.rotation-Tuple{CRSRotation}' href='#SatcomCoordinates.rotation-Tuple{CRSRotation}'><span class="jlbinding">SatcomCoordinates.rotation</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
rotation(t::AbstractAffineCRSTransform)
```


This function should return a `CRSRotation` object representing the rotation to align the starting CRS to the target CRS.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/functions/transforms.jl#L22-L26" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.wrap_spherical_angles-Union{Tuple{T}, Tuple{Union{Real, Unitful.Quantity{T, NoDims, Unitful.FreeUnits{°,, NoDims, nothing}} where T, Unitful.Quantity{T, NoDims, Unitful.FreeUnits{rad,, NoDims, nothing}} where T}, Union{Real, Unitful.Quantity{T, NoDims, Unitful.FreeUnits{°,, NoDims, nothing}} where T, Unitful.Quantity{T, NoDims, Unitful.FreeUnits{rad,, NoDims, nothing}} where T}, Type{T}}} where T<:Union{AER, AzOverEl, ElOverAz, ThetaPhi}' href='#SatcomCoordinates.wrap_spherical_angles-Union{Tuple{T}, Tuple{Union{Real, Unitful.Quantity{T, NoDims, Unitful.FreeUnits{°,, NoDims, nothing}} where T, Unitful.Quantity{T, NoDims, Unitful.FreeUnits{rad,, NoDims, nothing}} where T}, Union{Real, Unitful.Quantity{T, NoDims, Unitful.FreeUnits{°,, NoDims, nothing}} where T, Unitful.Quantity{T, NoDims, Unitful.FreeUnits{rad,, NoDims, nothing}} where T}, Type{T}}} where T<:Union{AER, AzOverEl, ElOverAz, ThetaPhi}'><span class="jlbinding">SatcomCoordinates.wrap_spherical_angles</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
az, el = wrap_spherical_angles(az::ValidAngle, el::ValidAngle, ::Type{<:ThetaPhi}) where T <: Deg{<:Real}
θ, φ = wrap_spherical_angles(θ::ValidAngle, φ::ValidAngle, ::Type{<:Union{AzOverEl, ElOverAz}}) where T <: Deg{<:Real}
```


Function that takes as input two angles representing two orthogonal angular components of spherical coordinates (e.g. θ/φ, el/az, etc.) and returns two angles normalized to a consistent wrapping identifying the full sphere:
- `θ/φ` angles are wrapped such that `θ ∈ [0°, 180°]` and `φ ∈ [-180°, 180°]`
  
- `el/az` angles are wrapped such that `el ∈ [-90°, 90°]` and `az ∈ [-180°, 180°]`
  

!!! 


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/utils.jl#L121-L130" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='SatcomCoordinates.wrap_spherical_angles_normalized-Union{Tuple{T}, Tuple{T, T, Type{<:Union{AER, AzEl, AzOverEl, ElOverAz}}}} where T<:Unitful.Quantity{<:Real, NoDims, Unitful.FreeUnits{°,, NoDims, nothing}}' href='#SatcomCoordinates.wrap_spherical_angles_normalized-Union{Tuple{T}, Tuple{T, T, Type{<:Union{AER, AzEl, AzOverEl, ElOverAz}}}} where T<:Unitful.Quantity{<:Real, NoDims, Unitful.FreeUnits{°,, NoDims, nothing}}'><span class="jlbinding">SatcomCoordinates.wrap_spherical_angles_normalized</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
az, el = wrap_spherical_angles_normalized(az::T, el::T, ::Type{<:ThetaPhi}) where T <: Deg{<:Real}
θ, φ = wrap_spherical_angles_normalized(θ::T, φ::T, ::Type{<:Union{AzOverEl, ElOverAz}}) where T <: Deg{<:Real}
```


Function that takes as input two angles representing two orthogonal angular components of spherical coordinates (e.g. θ/φ, el/az, etc.) and returns two angles normalized to a consistent wrapping identifying the full sphere:
- `θ/φ` angles are wrapped such that `θ ∈ [0°, 180°]` and `φ ∈ [-180°, 180°]`
  
- `el/az` angles are wrapped such that `el ∈ [-90°, 90°]` and `az ∈ [-180°, 180°]`
  

::: tip Note

This function already assumes that the provided input angles are already normalized such that both are in the [-180°, 180°] range. If you want to normalize the inputs automatically use the `wrap_first_angle` function.

:::


<Badge type="info" class="source-link" text="source"><a href="https://github.com/JuliaSatcomFramework/SatcomCoordinates.jl/blob/57740ad135dc7d8efd4d561f2332a459d505b64c/src/utils.jl#L96-L106" target="_blank" rel="noreferrer">source</a></Badge>

</details>

