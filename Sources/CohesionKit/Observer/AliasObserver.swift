import Foundation

// A type registering observers over an aliased entity
public struct AliasObserver<T>: Observer {
    typealias OnChangeClosure = (T?) -> Void

    public var value: T?
    /// a closure redirecting to the right observe method depending on T type
    let createObserve: (@escaping OnChangeClosure) -> Subscription

    /// create an observer for a single entity node ref
    init(alias: Observable<EntityNode<T>?>, registry: ObserverRegistry) {
        self.value = alias.value?.ref.value
        self.createObserve = {
            Self.createObserve(for: alias, registry: registry, onChange: $0)
        }
    }

    /// create an observer for a list of node ref
    init<E>(alias: Observable<[EntityNode<E>]?>, registry: ObserverRegistry) where T == Array<E> {
        self.value = alias.value?.map(\.ref.value)
        self.createObserve = {
            Self.createObserve(for: alias, registry: registry, onChange: $0)
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
        for alias: Observable<EntityNode<T>?>,
        registry: ObserverRegistry,
        onChange: @escaping OnChangeClosure
    ) -> Subscription {
        // register for current alias value
        var entityChangesSubscription: Subscription? = alias
            .value
            .map { node in registry.addObserver(node: node, initial: true, onChange: onChange) }

        // subscribe to alias changes
        let subscription = alias.addObserver { node in
            // update entity changes subscription
            entityChangesSubscription = node.map { registry.addObserver(node: $0, initial: true, onChange: onChange) }
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
        for alias: Observable<[EntityNode<E>]?>,
        registry: ObserverRegistry,
        onChange: @escaping OnChangeClosure
    ) -> Subscription where T == Array<E> {
        // register for current alias value
        var entitiesChangesSubscriptions: Subscription? = alias
            .value
            .map { nodes in EntityObserver(nodes: nodes, registry: registry) }?
            .observe(onChange: onChange)

        // Subscribe to alias ref changes and to any changes made on the ref collection nodes.
        let subscription = alias.addObserver { nodes in
            let nodeObservers = nodes.map { EntityObserver(nodes: $0, registry: registry) }

            // update collection changes subscription
            entitiesChangesSubscriptions = nodeObservers?.observe(onChange: onChange)
        }

        return Subscription {
            subscription.unsubscribe()
            entitiesChangesSubscriptions?.unsubscribe()
        }
      }
}
