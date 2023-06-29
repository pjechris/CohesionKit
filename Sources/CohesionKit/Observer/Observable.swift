import Foundation

public class Subscription {
    public let unsubscribe: () -> Void

    init(unsubscribe: @escaping () -> Void) {
        var unsubscribed = false

        self.unsubscribe = {
            if !unsubscribed {
                unsubscribe()
            }

            unsubscribed = true
        }
    }

    deinit {
        unsubscribe()
    }
}

protocol AnyRef { }

/// A class holding a value that can be observed when reference changes
class Observable<T>: AnyRef {
    typealias ObserverID = UUID

    var value: T {
        didSet {
            observers.values.forEach { $0(value) }
        }
    }
    private var observers: [UUID: (T) -> Void] = [:]

    init(value: T) {
        self.value = value
    }

    func addObserver(onChange: @escaping (T) -> Void) -> Subscription {
        let uuid = UUID()

        observers[uuid] = onChange

        return Subscription {
            self.observers.removeValue(forKey: uuid)
        }
    }
}
