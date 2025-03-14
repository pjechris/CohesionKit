/// a unique identifier to observe an object
struct Identifier: Hashable, Sendable, ExpressibleByStringLiteral {
  let identifier: String

  init(_ identifier: String) {
    self.identifier = identifier
  }

  init(stringLiteral value: StringLiteralType) {
    self.init(value)
  }

  /// Generates an identifier for type T with key as key
  init<T>(for type: T.Type, key: Any) {
    self.init("\(T.self):\(key)")
  }

  init<T: Identifiable>(for object: T) {
    self.init(for: T.self, key: object.id)
  }

  init<T>(for type: T.Type, key: AliasKey<T>) {
    self.init("alias:\(T.self):\(key.name)")
  }
}
