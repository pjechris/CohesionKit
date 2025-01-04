import Foundation

/// A type registering observers on a given entity from identity storage
public struct EntityObserver<T> {
    public typealias OnChange = (T) -> Void

    public let value: T

    private let createObserver: (@escaping OnChange) -> Subscription
    /// will be executed either on:
    ///
    /// - EntityObserver "deinit" if no observer was created
    /// - Once the observer stops observing
    private let onUnobserved: Subscription

    /// - Parameter onUnobserved: execute when no observer is left (either because no observer was created or because observer was removed)
    init(node: EntityNode<T>, registry: ObserverRegistry, onUnobserved: Subscription) {
        self.init(value: node.value, onUnobserved: onUnobserved) { onChange in
            registry
                .addObserver(node: node, initial: true, onChange: onChange)
        }
    }

    init<Element>(nodes: [EntityNode<Element>], registry: ObserverRegistry, onUnobserved: Subscription) where T == [Element] {
        self.init(value: nodes.map(\.value), onUnobserved: onUnobserved) { onChange in
            registry
                .addObserver(nodes: nodes, initial: true, onChange: onChange)
        }
    }

    init<Wrapped>(alias node: EntityNode<AliasContainer<Wrapped>>, registry: ObserverRegistry, onUnobserved: Subscription)
    where T == Optional<Wrapped> {
        self.init(value: node.value.content, onUnobserved: onUnobserved) { onChange in
            registry
                .addObserver(node: node, initial: true, onChange: { container in
                    onChange(container.content)
                })
        }
    }

    init(value: T, onUnobserved: Subscription, createObserver: @escaping (@escaping OnChange) -> Subscription) {
        self.value = value
        self.onUnobserved = onUnobserved
        self.createObserver = {
            createObserver($0)
                .merging(subscription: onUnobserved)
        }
    }

    public func observe(onChange: @escaping OnChange) -> Subscription {
        createObserver(onChange)
    }
}
