import Foundation

/// A storage keeping entities indexed by a unique key.
///
/// Storage keeps weak references to objects.
//// This allows to release entities automatically if no one is using them anymore (freeing memory space)
struct EntitiesStorage {
    /// the storage indexer. Stored content is [Identifier: Weak<EntityNode<Object>>]
    private typealias Storage = [Identifier: AnyWeak]

    private var indexes: Storage = [:]

    mutating func removeAll() {
        indexes.removeAll()
    }

    subscript<T: Identifiable>(_ type: T.Type, id id: T.ID) -> EntityNode<T>? {
      get { (indexes[Identifier(for: T.self, key: id)] as? Weak<EntityNode<T>>)?.value }
      set { indexes[Identifier(for: T.self, key: id)] = Weak(value: newValue) }
    }

    subscript(_ index: Identifier) -> AnyWeak? {
        get { indexes[index] }
        set { indexes[index] = newValue }
    }
}

extension EntitiesStorage {
    /// find or set a `EntityNode` associated with object
    subscript<T: Identifiable>(_ object: T) -> EntityNode<T>? {
        get { self[T.self, id: object.id] }
        set { self[T.self, id: object.id] = newValue }
    }

    /// - Parameter new: The value to create, store, and return if none is found
    subscript<T: Identifiable>(_ object: T, new create: @autoclosure () -> EntityNode<T>) -> EntityNode<T> {
        mutating get {
            if let value = self[T.self, id: object.id] {
                return value
            }

            let value = create()

            self[object] = value

            return value
        }
    }
}
