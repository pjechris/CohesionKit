import Foundation

/// A type registering observers on a given entity from identity storage
public struct EntityObserver<T>: Observer {
    let node: EntityNode<T>
    let queue: DispatchQueue
    public let value: T
    
    init(node: EntityNode<T>, queue: DispatchQueue) {
        self.queue = queue
        self.node = node
        self.value = node.value as! T
    }
    
    public func observe(onChange: @escaping (T) -> Void) -> Subscription {
        let subscription = node.ref.addObserver { newValue in
            queue.async {
                onChange(newValue)
            }
        }
        let retain = Unmanaged.passRetained(node)
        
        return Subscription {
            subscription.unsubscribe()
            retain.release()
        }
    }
}
