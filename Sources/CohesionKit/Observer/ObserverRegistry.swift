import Foundation

/// Registers observers associated to an ``EntityNode``.
/// The registry will handle notifying observers when a node is marked as changed
class ObserverRegistry {
    private typealias Hash = Int

    let queue: DispatchQueue
    /// registered observer handlers
    private var handlers: [Hash: Set<Handler>] = [:]
    /// nodes waiting for notifiying their observes about changes
    private var pendingChanges: [Hash: AnyWeak] = [:]

    init(queue: DispatchQueue? = nil) {
        self.queue = queue ?? DispatchQueue.main
    }

    /// register an observer to observe changes on an entity node. Everytime `ObserverRegistry` is notified about changes
    /// to this node `onChange` will be called.
    func addObserver<T>(node: EntityNode<T>, initial: Bool = false, onChange: @escaping (T) -> Void) -> Subscription {
        let handler = Handler { onChange($0.ref.value) }

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

        return subscribeHandler(handler, for: node)
    }

    func addObserver<T>(nodes: [EntityNode<T>], initial: Bool = false, onChange: @escaping ([T]) -> Void) -> Subscription {
        let handler = Handler { (_: EntityNode<T>) in
            // use last value from nodes
            onChange(nodes.map(\.ref.value))
        }

        if initial {
          if queue == DispatchQueue.main && Thread.isMainThread {
            onChange(nodes.map(\.ref.value))
          }
          else {
            queue.sync {
              onChange(nodes.map(\.ref.value))
            }
          }
        }

        let subscriptions = nodes.map { node in subscribeHandler(handler, for: node) }

        return Subscription {
            subscriptions.forEach { $0.unsubscribe() }
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
        let handlers = self.handlers
        var executedHandlers: Set<Handler> = []

        self.pendingChanges = [:]

        queue.async { [weak self] in
            guard let self else {
                return
            }

            for (hashKey, weakNode) in changes {
                // node was released: no one to notify
                guard let node = weakNode.unwrap() else {
                    continue
                }

                for handler in handlers[hashKey] ?? [] {
                    guard !executedHandlers.contains(handler) else {
                        continue
                    }

                    handler(node)
                    executedHandlers.insert(handler)
                }
            }
        }
    }

    private func subscribeHandler<T>(_ handler: Handler, for node: EntityNode<T>) -> Subscription {
        handlers[node.hashValue, default: []].insert(handler)

        // subscription keeps a strong ref to node, avoiding it from being released somehow while suscription is running
        return Subscription { [node] in
            self.handlers[node.hashValue]?.remove(handler)
        }
    }
}

extension ObserverRegistry {
    /// Handle observation for a given node
    class Handler: Hashable {
        let executor: (Any) -> Void

        init<T>(executor: @escaping (EntityNode<T>) -> Void) {
            self.executor = {
                guard let entity = $0 as? EntityNode<T> else {
                    return
                }

                executor(entity)
            }
        }

        /// execute the handler if `executeAtMost` does not exceed `executeCount`
        func callAsFunction(_ value: Any) {
            executor(value)
        }

        static func == (lhs: Handler, rhs: Handler) -> Bool {
            ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(self))
        }
    }
}