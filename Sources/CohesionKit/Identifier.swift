/// a unique identifier to observe an object
struct Identifier: Hashable, Sendable, ExpressibleByStringLiteral {
  let identifier: String

  init(identifier: String) {
    self.identifier = identifier
  }

  init(stringLiteral value: StringLiteralType) {
    self.init(identifier: value)
  }

  /// Generates an identifier for a node
  init<T>(node: EntityNode<T>) {
    self.init(identifier: "\(T.self)-\(node.hashValue)")
  }
}
