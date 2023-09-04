import Foundation

/// A type registering observers on a given entity from identity storage
public struct EntityObserver<T>: Observer {
    public typealias OnChange = (T) -> Void

    public let value: T

    let createObserver: (@escaping OnChange) -> Subscription

    init(node: EntityNode<T>, registry: ObserverRegistry) {
        self.value = node.ref.value
        self.createObserver = { onChange in
            registry.addObserver(node: node, initial: true, onChange: onChange)
        }
    }

    init<Element>(nodes: [EntityNode<Element>], registry: ObserverRegistry) where T == [Element] {
        self.value = nodes.map(\.ref.value)
        self.createObserver = { onChange in
            registry.addObserver(nodes: nodes, initial: true, onChange: onChange)
        }
    }

    public func observe(onChange: @escaping OnChange) -> Subscription {
        createObserver(onChange)
    }
}
