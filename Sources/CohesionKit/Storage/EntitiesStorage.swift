import Foundation

/// A storage keeping entities indexed by a unique key.
///
/// Storage keeps weak references to objects.
//// This allows to release entities automatically if no one is using them anymore (freeing memory space)
struct EntitiesStorage {
    /// the storage indexer. Stored content is [String: Weak<EntityNode<Object>>]
    private typealias Storage = [String: AnyWeak]

    private var indexes: Storage = [:]

    mutating func removeAll() {
        indexes.removeAll()
    }

    subscript<T: Identifiable>(_ type: T.Type, id id: T.ID) -> EntityNode<T>? {
        get { (indexes[key(for: T.self, id: id)] as? Weak<EntityNode<T>>)?.value }
        set { indexes[key(for: T.self, id: id)] = Weak(value: newValue) }
    }

    subscript(_ key: String) -> AnyWeak? {
        get { indexes[key] }
        set { indexes[key] = newValue }
    }

    private func key<T>(for type: T.Type, id: Any) -> String {
        "\(type)-\(id)"
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
