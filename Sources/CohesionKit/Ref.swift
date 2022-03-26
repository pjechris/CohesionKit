import Foundation

typealias Subscription = () -> Void

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
        
        return {
            self.observers.removeValue(forKey: uuid)
        }
    }
}
