/// A protocol allowing to observe a value returned from the `IdentityMap`
public protocol Observer {
    associatedtype T
    
    /// The value at the time the observer creation.
    /// If you want **realtime** value use `observe to get notified of changes
    var value: T { get }
    
    /// Add an observer being notified when entity change
    /// - Parameter onChange: a closure called when value changed
    /// - Returns: a subscription to cancel observation. Observation is automatically cancelled if subscription is deinit.
    /// As long as the subscription is alived the entity should be kept in `IdentityMap`.
    func observe(onChange: @escaping (T) -> Void) -> Subscription
}

extension Array: Observer where Element: Observer {
    public var value: [Element.T] { map(\.value) }
    
    public func observe(onChange: @escaping ([Element.T]) -> Void) -> Subscription {
        var value = value
        
        let subscriptions = indices.map { index in
            self[index].observe {
                value[index] = $0
                onChange(value)
            }
        }
        
        return Subscription {
            subscriptions.forEach { $0.unsubscribe() }
        }
    }
}
