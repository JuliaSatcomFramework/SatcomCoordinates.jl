# Changelog

This file contains the changelog for the SatcomCoordinates.jl package. It follows the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

## Unreleased

### Added
- Compared to pointing types in ReferenceViews.jl v0.2.0, 3 additional pointing are now available:
  - `PointingVersor`
  - `ElOverAz`
  - `AzOverEl`
### Changed
- Compared to the implementation in ReferenceViews.jl v0.2.0, most pointing and cartesian coordinates are now storing internally Unitful quantities, and structures are made parametric with respect to the number type of the fields.
- The `ThetaPhi` pointing type is now now _wrapping_ the values provided at its input, with Theta always being between 0° and 90° and Phi always between -180° and 180°.

### Deprecated
### Removed

### Fixed
### Security

