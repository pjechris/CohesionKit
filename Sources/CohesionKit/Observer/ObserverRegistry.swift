import Foundation

class ObserverRegistry {
    typealias Observer = (Any) -> Void
    typealias ObserverID = Int

    let queue: DispatchQueue
    private var observers: [Int: [ObserverID: Observer]] = [:]
    private var nextObserverID = 0

    init(queue: DispatchQueue) {
        self.queue = queue
    }

    /// register an observer for an entity node
    func registerObserver<T>(node: EntityNode<T>, onChange: @escaping (T) -> Void) -> Subscription {
        let observerUUID = generateID()
        let retain = Unmanaged.passRetained(node)

        observers[node.hashValue, default: [:]][observerUUID] = { [queue] in
            guard let newValue = $0 as? T else {
                return
            }

            queue.async {
                onChange(newValue)
            }
        }

        // TODO: Better deallocation management? (avoid using Unmanaged)
        // explicitly declare a strong ref to node object
        return Subscription { [node] in
            self.observers[node.hashValue]?.removeValue(forKey: observerUUID)
            retain.release()
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