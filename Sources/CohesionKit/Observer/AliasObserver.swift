// A type registering observers over an aliased entity
public struct AliasObserver<T>: Observer {
    typealias OnChangeClosure = (T?) -> Void
    
    public var value: T?
    // a closure redirecting to the right observe method depending on T type
    let createObserve: (@escaping OnChangeClosure) -> Subscription
    
    /// create an observer for a single entity node ref
    init(alias: Ref<EntityNode<T>?>) {
        self.value = alias.value?.ref.value
        self.createObserve = {
            Self.createObserve(for: alias, onChange: $0)
        }
    }
    
    /// create an observer for a list of node ref
    init<E>(alias: Ref<[EntityNode<E>]?>) where T == Array<E> {
        self.value = alias.value?.map(\.ref.value)
        self.createObserve = {
            Self.createObserve(for: alias, onChange: $0)
        }
    }
    
    public func observe(onChange: @escaping (T?) -> Void) -> Subscription {
        createObserve(onChange)
    }
}

extension AliasObserver {
    static func createObserve(for alias: Ref<EntityNode<T>?>, onChange: @escaping OnChangeClosure) -> Subscription {
        var nestedSubscription: Subscription? = nil

        let subscription = alias.addObserver { node in
            let nodeObserver = node.map(EntityObserver.init(node:))
            
            onChange(nodeObserver?.value)
            nestedSubscription = nodeObserver?.observe(onChange: onChange)
        }
        
        return Subscription {
            subscription.unsubscribe()
            nestedSubscription?.unsubscribe()
        }
    }
    
    static func createObserve<E>(for alias: Ref<[EntityNode<E>]?>, onChange: @escaping OnChangeClosure)
    -> Subscription where T == Array<E> {
        var nestedSubscription: Subscription? = nil

        let subscription = alias.addObserver { nodes in
            let nodeObservers = nodes.map { $0.map(EntityObserver.init(node:)) }
            
            onChange(nodeObservers?.value)
            
            nestedSubscription = nodeObservers?.observe(onChange: onChange)
        }
        
        return Subscription {
            subscription.unsubscribe()
            nestedSubscription?.unsubscribe()
        }
    }

}
