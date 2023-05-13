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
