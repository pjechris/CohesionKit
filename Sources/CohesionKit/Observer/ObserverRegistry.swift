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
        addHandler(node: node, initial: initial, onChange: onChange)
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

                self.handlers[hashKey]?.forEach { handle in handle(node) }
            }

            // reset handlers execution count for next postChanges calls
            for (hashKey, _) in changes {
                self.handlers[hashKey]?.forEach { handler in handler.resetExecuteCount() }
            }
        }
    }

    private func addHandler<T>(node: EntityNode<T>, initial: Bool = false, onChange: @escaping (T) -> Void) -> Subscription {
        let handler = Handler { onChange($0.ref.value) }

        handlers[node.hashValue, default: []].insert(handler)

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
            self.handlers[node.hashValue]?.remove(handler)
        }
    }
}

extension ObserverRegistry {
    /// Handle observation for a given node
    class Handler: Hashable {
        let executor: (Any) -> Void
        /// number of times an handler can be executed. By default it will be 1
        let executeAtMost: Int
        /// number of times handler was already executed
        private var executeCount = 0

        init<T>(executeAtMost: Int = 1, executor: @escaping (EntityNode<T>) -> Void) {
            self.executeAtMost = executeAtMost
            self.executor = {
                guard let entity = $0 as? EntityNode<T> else {
                    return
                }

                executor(entity)
            }
        }

        /// reset execution count allowing handler to re-execute if max execution was reached
        func resetExecuteCount() {
            executeCount = 0
        }

        /// execute the handler if `executeAtMost` does not exceed `executeCount`
        func callAsFunction(_ value: Any) {
            guard executeCount < executeAtMost else {
                return
            }

            executeCount += 1
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