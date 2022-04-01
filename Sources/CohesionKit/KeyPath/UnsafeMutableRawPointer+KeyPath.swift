import Foundation
import Accelerate

/// A collection providing an access to its buffer
public typealias BufferedCollection = Collection & AccelerateMutableBuffer

extension UnsafeMutableRawPointer {
    
    func assign<Root, Value>(_ value: Value, to keyPath: KeyPath<Root, Value>) {
        guard let offset = MemoryLayout<Root>.offset(of: keyPath) else {
            fatalError("offset for KeyPath<\(Root.self), \(Value.self)> is nil")
        }
        
        advanced(by: offset)
            .assumingMemoryBound(to: Value.self)
            .pointee = value
    }
    
    func assign<Root, C>(_ value: C.Element, to keyPath: KeyPath<Root, C>, index: C.Index)
      where C: BufferedCollection, C.Index == Int {

        guard let offset = MemoryLayout<Root>.offset(of: keyPath) else {
            fatalError("offset for KeyPath<\(Root.self), \(C.self)> is nil")
        }

        advanced(by: offset)
            .assumingMemoryBound(to: C.self)
            .pointee
            .withUnsafeMutableBufferPointer { $0[index] = value }
      }
}
