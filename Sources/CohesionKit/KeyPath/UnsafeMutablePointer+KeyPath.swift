import Foundation

extension UnsafeMutableRawPointer {
    
    func assign<Root, Value>(_ value: Value, to keyPath: KeyPath<Root, Value>) {
        guard let pointer = UnsafeMutablePointer(mutating: self.assumingMemoryBound(to: Root.self).pointer(to: keyPath)) else {
              fatalError("cannot update value for KeyPath<\(Root.self), \(Value.self)>. Computed properties are not supported.")
        }

        pointer.pointee = value
    }
    
    func assign<Root, C>(_ value: C.Element, to keyPath: KeyPath<Root, C>, index: C.Index)
      where C: MutableCollection, C.Index == Int {

        guard let pointer = UnsafeMutablePointer(mutating: self.assumingMemoryBound(to: Root.self).pointer(to: keyPath)) else {
              fatalError("cannot update value for KeyPath<\(Root.self), \(C.self)>. Computed properties are not supported.")
        }

        pointer.pointee.withContiguousMutableStorageIfAvailable { $0[index] = value }
      }
}

extension UnsafeMutablePointer {

    func assign<Value>(_ value: Value, to keyPath: KeyPath<Pointee, Value>) {

        guard let unsafePointer = UnsafeMutablePointer<Value>(mutating: pointer(to: keyPath)) else {
            fatalError("cannot update value for KeyPath<\(Pointee.self), \(Value.self)>. Computed properties are not supported.")
        }

        unsafePointer.pointee = value
    }
    
    func assign<C: MutableCollection>(_ value: C.Element, to keyPath: KeyPath<Pointee, C>, index: C.Index)
    where C.Index == Int {

        guard let unsafePointer = UnsafeMutablePointer<C>(mutating: pointer(to: keyPath)) else {
              fatalError("cannot update value for KeyPath<\(Pointee.self), \(C.self)>. Computed properties are not supported.")
        }

        unsafePointer.pointee.withContiguousMutableStorageIfAvailable { $0[index] = value }
    }
}
