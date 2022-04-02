import Foundation

public class Subscription {
    public let unsubscribe: () -> Void
    
    init(unsubscribe: @escaping () -> Void) {
        self.unsubscribe = unsubscribe
    }
    
    deinit {
        unsubscribe()
    }
}

/// A class holding a value
class Ref<T> {
    
    var value: T {
        didSet {
            observers.values.forEach { $0(value) }
        }
    }
    private var observers: [UUID: (T) -> Void] = [:]
    
    init(value: T) {
        self.value = value
    }
    
    func addObserver(_ onChange: @escaping (T) -> Void) -> Subscription {
        let uuid = UUID()
        
        observers[uuid] = onChange
        
        return Subscription {
            self.observers.removeValue(forKey: uuid)
        }
    }
}
