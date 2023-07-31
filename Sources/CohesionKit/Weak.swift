import Foundation

protocol AnyWeak: AnyObject {
    func unwrap() -> Any?
}

/// An object holding a weak reference on another object
class Weak<T: AnyObject>: AnyWeak {
    weak var value: T?

    init(value: T?) {
        self.value = value
    }

    func unwrap() -> Any? {
        value
    }
}
