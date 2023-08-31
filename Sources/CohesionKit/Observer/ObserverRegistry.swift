import Foundation

/// Registers observers associated to an ``EntityNode``.
/// The registry will handle notifying observers when a node is marked as changed
class ObserverRegistry {
    typealias Observer = (Any) -> Void
    private typealias ObserverID = Int
    private typealias Hash = Int

    let queue: DispatchQueue
    /// registered observers
    private var observers: [Hash: [ObserverID: Observer]] = [:]
    /// next available id for an observer
    private var nextObserverID: ObserverID = 0
    /// nodes waiting for notifiying their observes about changes
    private var pendingChanges: [Hash: AnyWeak] = [:]

    init(queue: DispatchQueue? = nil) {
        self.queue = queue ?? DispatchQueue(label: "com.cohesionkit.registry")
    }

    /// register an observer to observe changes on an entity node. Everytime `ObserverRegistry` is notified about changes
    /// to this node `onChange` will be called.
    func addObserver<T>(node: EntityNode<T>, initial: Bool = false, onChange: @escaping (T) -> Void) -> Subscription {
        let observerID = generateID()

        observers[node.hashValue, default: [:]][observerID] = {
            guard let newValue = $0 as? EntityNode<T> else {
                return
            }

            onChange(newValue.ref.value)
        }

        if initial {
          if queue == DispatchQueue.main && Thread.isMainThread {
            onChange(node.ref.value)
          }
          else {
            queue.sync {
              onChange(node.ref.value)
            }
          }
        }

        // subscription keeps a strong ref to node, avoiding it from being released somehow while suscription is running
        return Subscription { [node] in
            self.observers[node.hashValue]?.removeValue(forKey: observerID)
        }
    }

    /// Mark a node as changed. Observers won't be notified of the change until ``postChanges`` is called
    func enqueueChange<T>(for node: EntityNode<T>) {
        pendingChanges[node.hashValue] = Weak(value: node)
    }

    func hasPendingChange<T>(for node: EntityNode<T>) -> Bool {
        pendingChanges[node.hashValue] != nil
    }

    /// Notify observers of all queued changes. Once notified pending changes are cleared out.
    func postChanges() {
        let changes = pendingChanges
        let observers = self.observers

        self.pendingChanges = [:]

        queue.async { [unowned self] in
            for (hashKey, weakNode) in changes {
                // node was released: no one to notify
                guard let node = weakNode.unwrap() else {
                    continue
                }

                observers[hashKey]?.forEach { (_, observer) in
                    observer(node)
                }
            }
        }
    }

    private func generateID() -> ObserverID {
      defer { nextObserverID &+= 1 }
      return nextObserverID
    }
}
