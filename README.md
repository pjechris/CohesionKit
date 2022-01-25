# CohesionKit

![swift](https://img.shields.io/badge/Swift-5.1%2B-orange?logo=swift&logoColor=white)
![platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS-lightgrey)
![tests](https://github.com/pjechris/CohesionKit/actions/workflows/test.yml/badge.svg)
[![twitter](https://img.shields.io/badge/twitter-pjechris-1DA1F2?logo=twitter&logoColor=white)](https://twitter.com/pjechris)

Stop having your data not always up-to-date and not synchronized between screens!

Implemented with latest Swift technologies:

- 📇 `Identifiable` protocol
- 🧰 `Combine` framework
- 👀 `@dynamicMemberLookup`

# Why using it?

- 🦕 You don't use and/or don't want to use heavy frameworks like CoreData, Realm,... to keep in-memory data sync
- 🪶 You look for a lightweight tool
- 🗃️ You want to use structs
- 🔁 You have realtime data in your app (through websockets for instance)
- 🐛 You have data sync issues and want to get rid of it
- 📱 You display same data in multiple screens

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

1. Load your data as usual (WebService, GraphQL, DB, ...). Instead of returning them directly you pass the data to an object (`IdentityRegistry`) to track them using their identity.
1. You ask `IdentityRegistry` for the data which will be returned as `Combine.AnyPublisher`. Now any updates that will be made into `IdentityRegistry` will be sent to you.
2. Send updates for these data to `IdentityRegistry`. Anyone that asked for them will then be notified of the updates thanks to `Combine.AnyPublisher`.

## Storing an object

First create an `IdentityRegistry`:

```swift
let registry = IdentityRegistry(store: IdentityStore())
```

When your object is a simple `Identifiable` you can store it directly in the registry:

```swift
let user = User(id: 42, name: "John Doe")

registry.for(User.self).store(user)
```

Your object can now be retrieved by **anyone**:

```swift
/// somewhere else in the code
registry.for(User.self).publisher(id: 42)
```

More realistic example would be to load and save User when calling a webservice, then just load it from the registry when looking for it:

```swift
func loadCurrentUser() -> AnyPublisher<User, Error> {
    loadMyUserFromWS()
        .map { registry.for(User.self).store($0) }
        .switchToLatest()
        .eraseToAnyPublisher()
}

func findCurrentUser() -> AnyPublisher<User, Never> {
    registry.for(User.self).publisher(id: 42)
}
```

> CohesionKit only keep in memory in-use data. When no one is using some data (through subscription with sink/assign) CohesionKit will discard it from its memory. This allow to automatically clean memory.

## Storing a relational object

When dealing with complex objects containing other identity objects you'll have to use an additional object: `Relation`. `Relation` describe which children to store in order to keep them up-to-date.

> While complex objects DO exist in projects, we recommend to avoid deep nested relationships and we **strongly** advise to use [Aggregate objects](https://swiftunwrap.com/article/modeling-done-right/).

```swift
// 1. Create your model
struct ProductComments
  let product: Product
  let comments: [Comment]
}

// 2. Create a Relation object describing it
enum Relations {
  static let productComments =
    Relation(
        primaryChildPath: \ProductComments.product,
        otherChildren: [.init(\.product), .init(\.comments)]
    )
}

// 3. Then you can get/store it from/into the registry using your Relation entity
registry.for(Relations.productComments).store(ProductComment(...))
registry.for(Relations.productComments).publisher(id: xx)
```

## Aliases

Sometimes you need to retrieve data without knowing the id. Common case is current user: while above we request it using its id most of the time you just want to ask for the current user.

You can do this with registry using "alias" property. First register a data under an alias:

```swift
registry.for(User.self).store(myUser, aliased: "current_user")
```

Then request somewhere else:

```swift
registry.for(User.self).publisher(aliased: "current_user")
```

Some very important notes about aliases: while values are automatically released by the library those referenced by an alias will be kept **strongly**.

## Stale data

When updating data into the registry CohesionKit actually require you to set a modification stamp on it. Stamp is used to as a maker to compare which data is the most recent: the highest is considered as the most recent.

By default CohesionKit will use the current date as stamp.

```swift
registry.for(..).store(xxx) // use default stamp: current date
registry.for(..).store(xxx, modifiedAt: Date().stamp) // explicitly use Date time stamp
registry.for(..).store(xxx, modifiedAt: 9000) // any Double value is valid
```

# License

This project is released under the MIT License. Please see the LICENSE file for details.
