# Performance Examples
## Setup
```@example asd
using PrettyChairmarks
using SatcomCoordinates
uv = rand(UV)
# We convert from UV instead of doing all rand to avoid error for the limited domain of UV
tp = convert(ThetaPhi, uv)
el_az = convert(ElOverAz, uv)
az_el = convert(AzOverEl, uv)
pv = convert(PointingVersor, uv)
```

## Construction
### UV
```@example asd
@bs Tuple(rand(2)./10) UV(_...)
```
### ThetaPhi
```@example asd
@bs Tuple(rand(2)) ThetaPhi(_...)
```
### ElOverAz
```@example asd
@bs Tuple(rand(2)) ElOverAz(_...)
```
### AzOverEl
```@example asd
@bs Tuple(rand(2)) AzOverEl(_...)
```
### PointingVersor
```@example asd
@bs Tuple(rand(3)) PointingVersor(_...)
```
### ECEF
```@example asd
@bs Tuple(rand(3)) ECEF(_...)
```
### ECI
```@example asd
@bs Tuple(rand(3)) ECI(_...)
```
### LLA
```@example asd
@bs Tuple(rand(3)) LLA(_...)
```

## Conversions
### From PointingVersor
```@example asd
@bs convert(UV, $pv)
```
```@example asd
@bs convert(ThetaPhi, $pv)
```
```@example asd
@bs convert(ElOverAz, $pv)
```
```@example asd
@bs convert(AzOverEl, $pv)
```

### from UV
```@example asd
@bs convert(ThetaPhi, $uv)
```
```@example asd
@bs convert(ElOverAz, $uv)
```
```@example asd
@bs convert(AzOverEl, $uv)
```
```@example asd
@bs convert(PointingVersor, $uv)
```

### from ThetaPhi
```@example asd
@bs convert(UV, $tp)
```
```@example asd
@bs convert(ElOverAz, $tp)
```
```@example asd
@bs convert(AzOverEl, $tp)
```
```@example asd
@bs convert(PointingVersor, $tp)
```

### from ElOverAz
```@example asd
@bs convert(UV, $el_az)
```
```@example asd
@bs convert(ThetaPhi, $el_az)
```
```@example asd
@bs convert(AzOverEl, $el_az)
```
```@example asd
@bs convert(PointingVersor, $el_az)
```

### from AzOverEl
```@example asd
@bs convert(UV, $az_el)
```
```@example asd
@bs convert(ThetaPhi, $az_el)
```
```@example asd
@bs convert(ElOverAz, $az_el)
```
```@example asd
@bs convert(PointingVersor, $az_el)
```

## Utilities
### get_angular_distance
```@example asd
@bs Tuple(rand(ThetaPhi, 2)) get_angular_distance(_...)
```
```@example asd
@bs Tuple(rand(UV, 2)) get_angular_distance(_...)
```
```@example asd
@bs Tuple(rand(ElOverAz, 2)) get_angular_distance(_...)
```
```@example asd
@bs Tuple(rand(AzOverEl, 2)) get_angular_distance(_...)
```
```@example asd
@bs Tuple(rand(PointingVersor, 2)) get_angular_distance(_...)
```
### get_angular_offset
```@example asd
@bs Tuple(rand(ThetaPhi, 2)) get_angular_offset(_...)
```
```@example asd
@bs Tuple(rand(UV, 2)) get_angular_offset(_...)
```
```@example asd
@bs Tuple(rand(ElOverAz, 2)) get_angular_offset(_...)
```
```@example asd
@bs Tuple(rand(AzOverEl, 2)) get_angular_offset(_...)
```
```@example asd
@bs Tuple(rand(PointingVersor, 2)) get_angular_offset(_...)
```
### add_angular_offset
```@example asd
# We need to make sure we don't have a resulting target in -z axis hemisphere
@bs (UV(-rand(), 0), ThetaPhi(rand() * 90°, 0)) add_angular_offset(_...)
```
```@example asd
@bs (rand(ThetaPhi), rand(ThetaPhi)) add_angular_offset(_...)
```
```@example asd
@bs (rand(ElOverAz), rand(ThetaPhi)) add_angular_offset(_...)
```
```@example asd
@bs (rand(AzOverEl), rand(ThetaPhi)) add_angular_offset(_...)
```
```@example asd
@bs (rand(PointingVersor), rand(ThetaPhi)) add_angular_offset(_...)
```