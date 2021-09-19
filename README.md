# CohesionKit

![swift](https://img.shields.io/badge/Swift-5.1%2B-orange?logo=swift&logoColor=white)
![platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS-lightgrey)
![tests](https://github.com/pjechris/CohesionKit/actions/workflows/test.yml/badge.svg)
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
    .package(url: "https://github.com/pjechris/CohesionKit.git", .upToNextMajor(from: "0.1.0"))
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
let identityMap = IdentityMap()
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
        .map { identityMap.store($0) }
        .switchToLatest()
        .eraseToAnyPublisher()
}

func findCurrentUser() -> AnyPublisher<User, Never> {
    identityMap.publisher(for: User.self, id: 42)
}
```

> CohesionKit only keep in memory in-use data. When no one is using some data (through subscription with sink/assign) CohesionKit will discard it from its memory. This allow to automatically clean memory.

## Stale data

When updating data into the identity map CohesionKit actually require you to set a modification stamp on it. Stamp is used to make sure you're actually pass more recent data rather than old one.

You can use whatever you want as stamp as long as the type is `Double`

```swift
let identityMap = IdentityMap()

identityMap.store(xxx) // use default stamp: current date
identityMap.store(xxx, modifiedAt: Date().stamp) // explicitly use Date time stamp
identityMap.store(xxx, modifiedAt: 9000) // any Double value is valid
```

## Relationships

To store relational objects in identity map you must make your model conform to `IdentifiableGraph`. CohesionKit will then lookup for children objects and store them.

Nonetheless we strongly recommand to avoid deep nested relationships and we **strongly** advise to use [Aggregate objects](https://swiftunwrap.com/article/modeling-done-right/).

```swift
// 1. Create your model
struct ProductComments
  let product: Product
  let comments: [Comment]
}

// 2. Conform your model to Relational
extension ProductComments: Relational {

  var primaryKeyPath: KeyPath<Self, Product> { \.product }
  var relations: [IdentityKeyPath<Self>] { [.init(\.product), .init(\.comments)]}

  func reduce(changes: KeyPathUpdates<Self>) -> ProductComments {
      ProductComments(
          product: changes.product,
          comments: changes.comments
      )
  }
}

// 3. Then you can get/store it from/into IdentityMap
identityMap.update(ProductComment(...))
identityMap.publisher(for: ProductComments.self, id: xx)
```

# License

This project is released under the MIT License. Please see the LICENSE file for details.
