# CohesionKit

![swift](https://img.shields.io/badge/Swift-5.1%2B-orange?logo=swift&logoColor=white)
![platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS-lightgrey)
![tests](https://github.com/pjechris/CohesionKit/actions/workflows/test.yml/badge.svg)
[![twitter](https://img.shields.io/badge/twitter-pjechris-1DA1F2?logo=twitter&logoColor=white)](https://twitter.com/pjechris)

Simple data synchronisation in plain Swift.

## Overview

CohesionKit is a small library intended to remedy issues developers face when they try to display realtime data on multiple screens.

It is designed with latest Swift technologies:

- 📇 `Identifiable` protocol
- 🧰 `Combine` framework
- 👀 `KeyPath`

## When using it?

- 🔁 You need to show realtime data (websockets for instance)
- 🦕 You don't want to use a heavy frameworks like CoreData or Realm
- 🪶 You look for a lightweight tool
- 🗃️ You want to use structs

## Features

- [x] Thread safe
- [x] Lighweight (< 600 lines of code)
- [x] Simple API
- [x] Work with plain Swift `struct`
- [x] Work with `Identifiable` objects
- [x] Support for Combine
- [x] Use [aliases](#aliases) to reference named objects
- [x] Use [(time)stamps](#stale-data) to mark you data
- [x] In-memory storage
- [x] Release objects you're not actively using (weak memory)


## Installation

- Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/pjechris/CohesionKit.git", .upToNextMajor(from: "0.7.0"))
]
```

## Examples

This library come a very simple Example project so you can see a real case usage. It mostly show:

- How to store data in the library
- How to retrieve and update that data for realtime

## Getting started

### Store an object

First create an instance of `IdentityMap`:

```swift
let identityMap = IdentityMap()
```

`IdentityMap` let you store `Identifiable` objects:

```swift
struct Book: Identifiable {
  let id: String
  let title: String
}

let book = Book(id: "ABCD", name: "My Book")

identityMap.store(book)
```

Your can then retrieve the object anywhere in your code:

```swift
// somewhere else in the code
identityMap.find(Book.self, id: "ABCD") // return Book(id: "ABCD", name: "My Book")
```

### Listening to updates

Every time data is updated in `IdentityMap` will trigger a notification to any registered observer. To register yourself as an observer just use result from `store` or `find` methods:

```swift
func findBooks() {
  // 1. load data using URLSession
  URLSession(...)
  // 2. store data in `IdentityMap`
  // 3. return a `publisher` creating an observer
    .map { books in identityMap.store(books).asPublisher }
    .sink { ... }
    .store(in: &cancellables)
}
```

```swift
identityMap.find(Book.self, id: 1)?
  .asPublisher
  .sink { ... }
  .store(in: &cancellables)
```

> CohesionKit has a [weak memory policy](#weak-memory-management) you should understand.

### Relational objects

To store objects containing other objects you need to make them conform to one protocol: `Aggregate`.

```swift
struct AuthorBooks: Aggregate
  var id: Author.ID { author.id }

  let author: Author
  let books: [Book]

  // `nestedEntitiesKeyPaths` must list all Identifiable/Aggregate this object contain
  var nestedEntitiesKeyPaths: [PartialIdentifiableKeyPath<Self>] {
    [.init(\.author), .init(\.books)]
  }
}
```

CohesionKit will then handle synchronisation for the three entities:

- AuthorBook
- Author
- Book

This allow you to retrieve them independently from each other:

```swift
let authorBooks = AuthorBooks(
    author: Author(id: 1, name: "George R.R Martin"),
    books: [
      Book(id: "ACK", title: "A Clash of Kings"),
      Book(id: "ADD", title: "A Dance with Dragons")
    ]
)

identityMap.store(authorBooks)

identityMap.find(Author.self, id: 1) // George R.R Martin
identityMap.find(Book.self, id: "ACK") // A Clash of Kings
identityMap.find(Book.self, id: "ADD") // A Dance with Dragons
```

You can also modify any of them however you want:

```swift
let newAuthor = Author(id: 1, name: "George R.R MartinI")

identityMap.store(newAuthor)

identityMap.find(Author.self, id: 1) // George R.R MartinI
identityMap.find(AuthorBooks.self, id: 1 // George R.R MartinI + [A Clash of Kings, A Dance with Dragons]
```

## Advanced topics

### Weak memory management

CohesionKit has a weak memory policy: objects are kept in `IdentityMap` as long as someone use them.

To that end you need to retain observers as long as you're interested in the data:

```swift
let book = Book(id: "ACK", title: "A Clash of Kings")
let cancellable = identityMap.store(book) // observer is not retained and no one else observe this book: data is released

identityMap.find(Book.self, id: "ACK") // return  "A Clash of Kings"
```

If you don't create/retain observers then once entities have no more observers they will be automatically discarded from the storage.

```swift
let book = Book(id: "ACK", title: "A Clash of Kings")
_ = identityMap.store(book) // observer is not retained and no one else observe this book: data is released

identityMap.find(Book.self, id: "ACK") // return nil
```

```swift
let book = let book = Book(id: "ACK", title: "A Clash of Kings")
var cancellable = identityMap.store(book).asPublisher.sink { ... }
let cancellable2 = identityMap.find(Book.self, id: "ACK") // return a publisher

cancellable = nil

identityMap.find(Book.self, id: "ADD") // return "A Clash of Kings" because cancellable2 still observe this book
```

### Aliases

Sometimes you need to retrieve data without knowing the id. Common scenario is current user.

CohesionKit provide a suitable mechanism: aliases. Aliases allow you to register and find entities using a key.

```swift
extension AliasKey where T == User {
  static let currentUser = AliasKey("user")
}

identityMap.store(currentUser, named: \.currentUser)
```

Then request it somewhere else:

```swift
identityMap.find(named: \.currentUser) // return the current user
```

Compared to regular entities aliased objects are long-live objects: they will be kept in the storage even if no one observe them. This allow registered observers to be notified when alias value change:

```swift
identityMap.removeAlias(named: \.currentUser) // observers will be notified currentUser is nil.

identityMap.store(newCurrentUser, named: \.currentUser) // observers will be notified that currentUser changed even if currentUser was nil before
```

### Stale data

When storing data CohesionKit actually require you to set a modification stamp on it. `Stamp` is used as a marker to compare data freshness: the higher stamp is the more recent data is.

By default CohesionKit will use the current date as stamp.

```swift
identityMap.store(book) // use default stamp: current date
identityMap.store(book, modifiedAt: Date().stamp) // explicitly use Date time stamp
identityMap.store(book, modifiedAt: 9000) // any Double value is valid
```

If for some reason you try to store data with a stamp lower than the already stamped stored data then the update will be discarded.

# License

This project is released under the MIT License. Please see the LICENSE file for details.
