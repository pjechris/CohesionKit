import Foundation

/// A type registering observers on a given entity from identity storage
public struct EntityObserver<T> {
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

    init<Wrapped>(alias node: EntityNode<AliasContainer<Wrapped>>, registry: ObserverRegistry)
    where T == Optional<Wrapped> {
        self.init(value: node.ref.value.content) { onChange in
            registry.addObserver(node: node, initial: true, onChange: { container in
                onChange(container.content)
            })
        }
    }

    init(value: T, createObserver: @escaping (@escaping OnChange) -> Subscription) {
        self.value = value
        self.createObserver = createObserver
    }

    public func observe(onChange: @escaping OnChange) -> Subscription {
        createObserver(onChange)
    }
}
