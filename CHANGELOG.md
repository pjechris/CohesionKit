## Main branch

### Fixed

- When updating a graph relationships only one update should be triggered

## 0.3.0

### Breaking changes

- `IdentityMap<Stamp>` was replaced with `IdentityMap`
- `IdentityMap` now only accept `Double` values as stamp

### Added

- `Stamp` is now a typealias
- You can generate stamp right from `Date` using `Date().stamp`

### Fixed

- Fixed crash when cancelling subscription on a `IdentityGraph` object

## 0.2.0

### Added

- Added api to easily store relationship objects
- Added api to retrieve a sequence of objects at once
