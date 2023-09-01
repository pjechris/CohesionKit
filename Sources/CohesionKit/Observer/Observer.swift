/// A protocol allowing to observe a value returned from the `IdentityMap`
public protocol Observer {
    associatedtype T

    /// The value at the time the observer creation.
    /// If you want **realtime** value use `observe to get notified of changes
    var value: T { get }

    /// Add an observer being notified when entity change.
    /// Alternatively you can use `asPublisher` to observe using Combine.
    /// - Parameter onChange: a closure called when value changed
    /// - Returns: a subscription to cancel observation. Observation is automatically cancelled if subscription is deinit.
    /// As long as the subscription is alived the entity should be kept in `IdentityMap`.
    func observe(onChange: @escaping (T) -> Void) -> Subscription
}
