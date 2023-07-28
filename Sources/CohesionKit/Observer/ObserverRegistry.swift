import Foundation

/// Registers observers associated to an ``EntityNode``.
/// The registry will handle notifying observers when a node is marked as changed
class ObserverRegistry {
    typealias Observer = (Any) -> Void
    private typealias ObserverID = Int

    let queue: DispatchQueue
    /// registered observers
    private var observers: [AnyHashable: [ObserverID: Observer]] = [:]
    /// next available id for an observer
    private var nextObserverID: ObserverID = 0
    /// nodes waiting for notifiying their observes about changes
    private var pendingChanges: Set<AnyHashable> = []

    init(queue: DispatchQueue) {
        self.queue = queue
    }

    /// register an observer to observe changes on an entity node. Everytime `ObserverRegistry` is notified about changes
    /// to this node `onChange` will be called.
    func addObserver<T>(node: EntityNode<T>, onChange: @escaping (T) -> Void) -> Subscription {
        let observerID = generateID()

        observers[node.hashValue, default: [:]][observerID] = {
            guard let newValue = $0 as? T else {
                return
            }

            onChange(newValue)
        }

        // subscription keeps a strong ref to node, avoiding it from being released somehow while suscription is running
        return Subscription { [node] in
            self.observers[node.hashValue]?.removeValue(forKey: observerID)
        }
    }

    /// Mark a node as changed. Observers won't be notified of the change until ``postChanges`` is called
    func enqueueChange<T>(for node: EntityNode<T>) {
        pendingChanges.insert(AnyHashable(node))
    }

    /// Notify observers of all queued changes. Once notified pending changes are cleared out.
    func postChanges() {
        /// keep notifications as-is when queue was triggered
        queue.async { [weak self] in
            guard let self else {
                return
            }

            let changes = self.pendingChanges

            self.pendingChanges = []

            for hash in changes {
                let node = hash.base as! AnyEntityNode

                self.observers[hash.hashValue]?.forEach { (_, observer) in
                    observer(node.value)
                }
            }
        }
    }

    private func generateID() -> ObserverID {
      defer { nextObserverID &+= 1 }
      return nextObserverID
    }
}