import Foundation

class ObserverRegistry {
    typealias Observer = (Any) -> Void
    private typealias ObserverID = Int
    private typealias EntityNodeKey = Int

    let queue: DispatchQueue
    /// registered observers per node
    private var observers: [EntityNodeKey: [ObserverID: Observer]] = [:]
    /// next available id for an observer
    private var nextObserverID: ObserverID = 0
    /// nodes waiting for notifiying their observes about changes
    private var pendingChangedNodes: Set<AnyHashable> = []

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

    func postNotification<T>(for node: EntityNode<T>) {
        self.observers[node.hashValue]?.forEach { (_, observer) in
            observer(node.value)
        }
    }

    /// Queue a notification for given node. Notification won't be sent until ``postNotifications`` is called
    func enqueueNotification<T>(for node: EntityNode<T>) {
        pendingChangedNodes.insert(AnyHashable(node))
    }

    /// Notify observers of all queued changes. Once notified pending changes are cleared out.
    func postNotifications() {
        /// keep notifications as-is when queue was triggered
        queue.async { [weak self] in
            guard let self else {
                return
            }

            let changes = self.pendingChangedNodes

            self.pendingChangedNodes = []

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