import Foundation

extension UnsafeMutablePointer {

    func assign<Value>(_ value: Value, to keyPath: KeyPath<Pointee, Value>) {

        guard let unsafeValuePointer = UnsafeMutablePointer<Value>(mutating: pointer(to: keyPath)) else {
            fatalError("cannot update value for KeyPath<\(Pointee.self), \(Value.self)>: failed to access memory pointer.")
        }

        unsafeValuePointer.pointee = value
    }

    func assign<C: MutableCollection>(_ value: C.Element, to keyPath: KeyPath<Pointee, C>, index: C.Index) {

        guard let unsafeCollectionPointer = UnsafeMutablePointer<C>(mutating: pointer(to: keyPath)) else {
            fatalError("cannot update value for KeyPath<\(Pointee.self), \(C.self)>: failed to access memory pointer.")
        }

        /// calculate the distance in memory where the object is located to update it
        let distance = unsafeCollectionPointer
            .pointee
            .distance(from: unsafeCollectionPointer.pointee.startIndex, to: index)

        // unsafeCollectionPointer.pointee.withUnsafeMutableBufferPointer { $0[distance] = value }
    }
}
