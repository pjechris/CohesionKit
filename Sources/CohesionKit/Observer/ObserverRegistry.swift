import Foundation

class ObserverRegistry {
    typealias Observer = (Any) -> Void
    private typealias ObserverID = Int
    private typealias EntityNodeKey = Int

    let queue: DispatchQueue
    /// registered observers per node
    private var observers: [EntityNodeKey: [ObserverID: Observer]] = [:]
    private var nextObserverID = 0

    init(queue: DispatchQueue) {
        self.queue = queue
    }

    /// register an observer for an entity node
    func registerObserver<T>(node: EntityNode<T>, onChange: @escaping (T) -> Void) -> Subscription {
        let observerUUID = generateID()

        observers[node.hashValue, default: [:]][observerUUID] = { [queue] in
            guard let newValue = $0 as? T else {
                return
            }

            queue.async {
                onChange(newValue)
            }
        }

        // subscription keeps a strong ref to node, avoiding it from being released somehow while suscription is running
        return Subscription { [node] in
            self.observers[node.hashValue]?.removeValue(forKey: observerUUID)
        }
    }

    /// add a pending observer to a unknown entity using its id
    func addObserver<T>(id: String, onChange: @escaping (T) -> Void) {

    }

    func notifyObservers<T>(for node: EntityNode<T>) {
        observers[node.hashValue]?.forEach { _, observer in
            observer(node.ref.value)
        }
    }

    private func generateID() -> ObserverID {
      defer { nextObserverID &+= 1 }
      return nextObserverID
    }
}