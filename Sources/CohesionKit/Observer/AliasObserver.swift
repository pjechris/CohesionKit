import Foundation

// A type registering observers over an aliased entity
public struct AliasObserver<T>: Observer {
    typealias OnChangeClosure = (T?) -> Void
    
    public var value: T?
    /// a closure redirecting to the right observe method depending on T type
    let createObserve: (@escaping OnChangeClosure) -> Subscription
    
    /// create an observer for a single entity node ref
    init(alias: Ref<EntityNode<T>?>, queue: DispatchQueue) {
        self.value = alias.value?.ref.value
        self.createObserve = {
            Self.createObserve(for: alias, queue: queue, onChange: $0)
        }
    }
    
    /// create an observer for a list of node ref
    init<E>(alias: Ref<[EntityNode<E>]?>, queue: DispatchQueue) where T == Array<E> {
        self.value = alias.value?.map(\.ref.value)
        self.createObserve = {
            Self.createObserve(for: alias, queue: queue, onChange: $0)
        }
    }
    
    public func observe(onChange: @escaping (T?) -> Void) -> Subscription {
        createObserve(onChange)
    }
}

extension AliasObserver {
    /// Create an observer sending updates every time:
    /// - the ref node change
    /// - the ref node value change
    private static func createObserve(
        for alias: Ref<EntityNode<T>?>,
        queue: DispatchQueue,
        onChange: @escaping OnChangeClosure
    ) -> Subscription {
        var entityChangesSubscription: Subscription? = alias
            .value
            .map { node in EntityObserver(node: node, queue: .main) }?
            .observe(onChange: onChange)

        // subscribe to alias changes
        let subscription = alias.addObserver { node in
            let nodeObserver = node.map { EntityObserver(node: $0, queue: queue) }

            queue.async { onChange(nodeObserver?.value) }
            // update entity changes subscription
            entityChangesSubscription = nodeObserver?.observe(onChange: onChange)
        }

        return Subscription {
            subscription.unsubscribe()
            entityChangesSubscription?.unsubscribe()
        }
    }

    /// Create an observer sending updates every time:
    /// - the ref node change
    /// - any of the ref node element change
  private static func createObserve<E>(
        for alias: Ref<[EntityNode<E>]?>,
        queue: DispatchQueue,
        onChange: @escaping OnChangeClosure
    ) -> Subscription where T == Array<E> {
        var entitiesChangesSubscriptions: Subscription? = alias
            .value
            .map { nodes in nodes.map { EntityObserver(node: $0, queue: queue) } }?
            .observe(onChange: onChange)

        // Subscribe to alias ref changes and to any changes made on the ref collection nodes.
        let subscription = alias.addObserver { nodes in
            let nodeObservers = nodes?.map { EntityObserver(node: $0, queue: queue) }

            queue.async { onChange(nodeObservers?.value) }

            // update collection changes subscription
            entitiesChangesSubscriptions = nodeObservers?.observe(onChange: onChange)
        }

        return Subscription {
            subscription.unsubscribe()
            entitiesChangesSubscriptions?.unsubscribe()
        }
    }

}
