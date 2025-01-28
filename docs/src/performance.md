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
@bs UV(.1,.1)
```
### ThetaPhi
```@example asd
@bs ThetaPhi(10,20)
```
### ElOverAz
```@example asd
@bs ElOverAz(10,20)
```
### AzOverEl
```@example asd
@bs AzOverEl(10,20)
```
### PointingVersor
```@example asd
@bs PointingVersor(1,2,3)
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
