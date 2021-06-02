# CohesionKit

![swift](https://img.shields.io/badge/Swift-5.1%2B-orange?logo=swift&logoColor=white)
![platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS-lightgrey)
[![twitter](https://img.shields.io/badge/twitter-pjechris-1DA1F2?logo=twitter&logoColor=white)](https://twitter.com/pjechris)

Stop having your data not always up-to-date and not synchronized between screens! 

Implemented with latest Swift technologies:

- 📇 `Identifiable` protocol
- 🧰 `Combine` framework

# Why using it?

- 🦕 You don't use (or don't want to use) heavy frameworks like CoreData, Realm,... to keep in-memory data sync
- 🪶 You want to be able to use structs
- 💡 You look for a lightweight framework
- 🔁 You do realtime in your app (through websockets for instance)
- 🐛 You have some sync issues in your app and want to deal with it
- 🛰️ You display same data in multiple screens

It's very unlikely your app will read and write data from only one class. You end up having to come up with all kind of clever mechanisms to communicate between your classes. They have to tell each other when there are changes, and if they should refresh the data they’ve fetched previously. CohesionKit intend to remedy these issues.

# Requirements

- iOS 13+ / macOS 10.15
- Swift 5.1+

# Installation

- Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/pjechris/IdentityMap.git", .upToNextMajor(from: "0.1.0"))
]
```

# Examples

This library come a very simple Example project so you can see a real case usage. It mostly show:

- How to store data in the library
- How to retrieve and update that data for realtime

# Basic Usage

CohesionKit is based on [Identity Map pattern](http://martinfowler.com/eaaCatalog/identityMap.html). Idea is to:

1. Load your data as usual (WebService, GraphQL, DB, ...). Instead of returning them directly you pass the data to an object (`IdentityMap`) to track them using their identity thanks to `Identifiable`.
1. You ask `IdentityMap` for the data which will be returned to you as `Combine.AnyPublisher`. Now any updates that will be made into `IdentityMap` will be sent to you.
2. Send updates for these data to `IdentityMap`. Anyone that asked for them will then be notified of the updates thanks to `Combine.AnyPublisher`.

## Adding an object

First create an `IdentityMap`:

```swift
let identityMap = IdentityMap<Date>()
```

Then add your object inside it:

```swift
let user = User(id: 42, name: "John Doe")

identityMap.update(user)
```

Your object is now in the identity map and can be retrieved by **anyone**:

```swift
identityMap.publisher(for: User.self, id: 42)
```

More realistic example would be to load and save User when calling a webservice, then just load it from the identity map when looking for it:

```swift
func loadCurrentUser() -> AnyPublisher<User, Error> {
    loadMyUserFromWS()
        .map { identityMap.update($0) }
        .switchToLatest()
        .eraseToAnyPublisher()
}

func findCurrentUser() -> AnyPublisher<User, Error> {
    identityMap.publisher(for: User.self, id: 42)
}
```

> CohesionKit only keep in memory in-use data. When no one is using some data (through subscription with sink/assign) CohesionKit will discard it from its memory. This allow to automatically clean memory.

## Stale data

When updating data into the identity map CohesionKit actually require you to set a stamp on it (like for mails). Stamp is used to make sure you're actually pass more recent data rather than old one.

You can use whatever you want as stamp as long as the type is `Comparable`. When using `Date` CohesionKit will use current date as default stamp:

```swift
let identityMap = IdentityMap<Date>() // stamp is of type Date

identityMap.update(xxx) // use default stamp: current date
identityMap.update(xxx, stamp: myCustomDate)

let identityMap = Identitymap<Int>() // stamp is of type Int

identityMap.update(xxx, stamp: 9000) // you have to provide a Int stamp
```

## Relationships

It is up to you to save relationships objects into the identity map. As such we **strongly** recommand to use [Aggregate objects](https://swiftunwrap.com/article/modeling-done-right/) so to avoid duplication data.

For now CohesionKit does not provide any helper to save, load and aggregate these relationships. This might change in upcoming releases.

```swift
struct ProductComments {
  let product: Product
  let comments: [Comment]
}

identityMap
    .publisher(for: Product.self, id: 1)
    .combineLatest([1, 2, 3, 4].map { identityMap.publisher(for: Comment.self, id: $0) }.combineLatest())
    .map { ProductComments(product: $0.0, comments: $0.1) }
    .eraseToAnyPublisher()
```

# License

This project is released under the MIT License. Please see the LICENSE file for details.
