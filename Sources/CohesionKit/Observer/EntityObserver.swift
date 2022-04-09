/// A type registering observers on a given entity from identity storage
public struct EntityObserver<T>: Observer {
    let node: EntityNode<T>
    public let value: T
    
    init(node: EntityNode<T>) {
        self.node = node
        self.value = node.value as! T
    }
    
    public func observe(onChange: @escaping (T) -> Void) -> Subscription {
        let subscription = node.ref.addObserver(onChange: onChange)
        let retain = Unmanaged.passRetained(node)
        
        return Subscription {
            subscription.unsubscribe()
            retain.release()
        }
    }
}
