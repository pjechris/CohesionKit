import Foundation

class ObserverRegistry {
    typealias Observer = (Any) -> Void

    private var observers: [String: [UUID: Observer]] = [:]
    let queue: DispatchQueue

    init(queue: DispatchQueue) {
        self.queue = queue
    }

    /// add an observer to an entity
    func addObserver<T>(node: EntityNode<T>, onChange: @escaping (T) -> Void) -> Subscription {
        let observerUUID = UUID()
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
}