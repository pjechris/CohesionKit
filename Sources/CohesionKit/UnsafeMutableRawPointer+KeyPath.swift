import Foundation

extension UnsafeMutableRawPointer {
    func assign<Root>(_ value: Any, to keyPath: PartialKeyPath<Root>) {
        func open<Value>(_: Value.Type) {
            assign(value as! Value, to: unsafeDowncast(keyPath, to: KeyPath<Root, Value>.self))
        }
        
        _openExistential(type(of: keyPath).valueType, do: open)
    }
    
    func assign<Root, Value>(_ value: Value, to keyPath: KeyPath<Root, Value>) {
        guard let offset = MemoryLayout<Root>.offset(of: keyPath) else {
            fatalError("offset for KeyPath<\(Root.self), \(Value.self)> is nil")
        }
        
        advanced(by: offset)
            .assumingMemoryBound(to: Value.self)
            .pointee = value
    }
}
