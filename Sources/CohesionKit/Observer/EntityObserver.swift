import Foundation

/// A type registering observers on a given entity from identity storage
public struct EntityObserver<T>: Observer {
    let node: EntityNode<T>
    let registry: ObserverRegistry
    public let value: T

    init(node: EntityNode<T>, registry: ObserverRegistry) {
        self.registry = registry
        self.node = node
        self.value = node.value as! T
    }

    public func observe(onChange: @escaping (T) -> Void) -> Subscription {
        registry.addObserver(node: node, initial: true, onChange: onChange)
    }
}
