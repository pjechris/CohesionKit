import Foundation

class ObserverRegistry {
    typealias Observer = (Any) -> Void

    let queue: DispatchQueue
    private var observers: [String: [Int: Observer]] = [:]
    private var nextObserverID = 0

    init(queue: DispatchQueue) {
        self.queue = queue
    }

    /// register an observer for an entity node
    func registerObserver<T>(node: EntityNode<T>, onChange: @escaping (T) -> Void) -> Subscription {
        let observerUUID = generateID()
        let retain = Unmanaged.passRetained(node)
        let key = "#TODO"

        observers[key, default: [:]][observerUUID] = { [queue] in
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
            self.observers[key]?.removeValue(forKey: observerUUID)
            retain.release()
        }
    }

    /// add a pending observer to a unknown entity using its id
    func addObserver<T>(id: String, onChange: @escaping (T) -> Void) {

    }

    func notifyObservers<T>(for entity: EntityNode<T>) {
        let key = "#TODO"
        observers[]?.forEach { _, observer in
            observer(entity.ref.value)
        }
    }

    private func generateID() -> Int {
      defer { nextObserverID &+= 1 }
      return nextObserverID
    }
}