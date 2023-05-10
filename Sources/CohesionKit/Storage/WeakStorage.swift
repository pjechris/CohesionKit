import Foundation

struct WeakStorage {
    typealias Storage = [String: AnyWeak]

    private var storage: Storage = [:]

    mutating func removeAll() {
        storage.removeAll()
    }

    subscript<T: AnyObject>(_ type: T.Type, id id: Any) -> T? {
        get { (storage[key(for: type, id: id)] as? Weak<T>)?.value }
        set { storage[key(for: type, id: id)] = Weak(value: newValue) }
    }

    private func key<T>(for type: T.Type, id: Any) -> String {
        "\(type)-\(id)"
    }
}

extension WeakStorage {
    /// find or set a `EntityNode` associated with object
    subscript<T: Identifiable>(_ object: T) -> EntityNode<T>? {
        get { self[EntityNode<T>.self, id: object.id] }
        set { self[EntityNode<T>.self, id: object.id] = newValue }
    }

    /// - Parameter new: The value to create, store, and return if none is found
    subscript<T: Identifiable>(_ object: T, new create: @autoclosure () -> EntityNode<T>) -> EntityNode<T> {
        mutating get {
            if let value = self[EntityNode<T>.self, id: object.id] {
                return value
            }

            let value = create()

            self[object] = value

            return value
        }
    }
}
