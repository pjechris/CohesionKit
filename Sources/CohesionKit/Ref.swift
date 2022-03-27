import Foundation

typealias Unsubscription = () -> Void

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
    
    func addObserver(_ onChange: @escaping (T) -> Void) -> Unsubscription {
        let uuid = UUID()
        
        observers[uuid] = onChange
        
        return {
            self.observers.removeValue(forKey: uuid)
        }
    }
}
