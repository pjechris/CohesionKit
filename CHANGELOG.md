## Main branch

### Added

- Ability to define aliases on stored values. This allow you to retrieve them without knowing their id.
- (Experimental) Added `Registry` on top of `IdentityMap`

### Fixed

- Fixed potential conflict in update when stamp was equal to previous update

## 0.4.0

### Breaking changes

- Methods named `update` and `updateIfPresent` were renamed `store` and `storeIfPresent`
- `IdentityGraph` is replaced by `Relation`. You should create relation objects in order to store data in IdentityMap. Have a look to the README for more details.

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
