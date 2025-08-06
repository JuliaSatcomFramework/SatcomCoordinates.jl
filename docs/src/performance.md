# Performance Examples
## Setup
```@example asd
using PrettyChairmarks
using SatcomCoordinates
uv = rand(UV())
# We change_crs from UV instead of doing all rand to avoid error for the limited domain of UV
tp = change_crs(ThetaPhi(), uv)
el_az = change_crs(ElOverAz(), uv)
az_el = change_crs(AzOverEl(), uv)
pv = change_crs(DirectionCosines(), uv)
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
### DirectionCosines
```@example asd
@bs Tuple(rand(3)) DirectionCosines(_...)
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
### From DirectionCosines
```@example asd
@bs change_crs(UV(), $pv)
```
```@example asd
@bs change_crs(ThetaPhi(), $pv)
```
```@example asd
@bs change_crs(ElOverAz(), $pv)
```
```@example asd
@bs change_crs(AzOverEl(), $pv)
```

### from UV
```@example asd
@bs change_crs(ThetaPhi(), $uv)
```
```@example asd
@bs change_crs(ElOverAz(), $uv)
```
```@example asd
@bs change_crs(AzOverEl(), $uv)
```
```@example asd
@bs change_crs(DirectionCosines(), $uv)
```

### from ThetaPhi
```@example asd
@bs change_crs(UV(), $tp)
```
```@example asd
@bs change_crs(ElOverAz(), $tp)
```
```@example asd
@bs change_crs(AzOverEl(), $tp)
```
```@example asd
@bs change_crs(DirectionCosines(), $tp)
```

### from ElOverAz
```@example asd
@bs change_crs(UV(), $el_az)
```
```@example asd
@bs change_crs(ThetaPhi(), $el_az)
```
```@example asd
@bs change_crs(AzOverEl(), $el_az)
```
```@example asd
@bs change_crs(DirectionCosines(), $el_az)
```

### from AzOverEl
```@example asd
@bs change_crs(UV(), $az_el)
```
```@example asd
@bs change_crs(ThetaPhi(), $az_el)
```
```@example asd
@bs change_crs(ElOverAz(), $az_el)
```
```@example asd
@bs change_crs(DirectionCosines(), $az_el)
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
@bs Tuple(rand(DirectionCosines, 2)) get_angular_distance(_...)
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
@bs Tuple(rand(DirectionCosines, 2)) get_angular_offset(_...)
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
@bs (rand(DirectionCosines), rand(ThetaPhi)) add_angular_offset(_...)
```