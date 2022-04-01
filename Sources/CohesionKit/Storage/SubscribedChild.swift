/// A child subscription used by its parent
struct SubscribedChild {
    /// the child subscription. Use it to unsubscribe to child upates
    let subscription: Subscription
    /// the child node value
    let node: AnyEntityNode
    /// a type erasing closure allowing to set the child value on its parent without knowing its concrete type
    /// - Parameter: a pointer to the parent
    let selfAssignTo: (UnsafeMutableRawPointer) -> Void
}
