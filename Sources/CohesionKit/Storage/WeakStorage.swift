import Foundation

struct WeakStorage {
    typealias Storage = [String: AnyWeak]
    
    private var storage: Storage = [:]
    
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
}
