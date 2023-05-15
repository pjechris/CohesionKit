import Foundation

/// A collection providing an access to its buffer.
/// 
/// Idea was to directly use `BufferedCollection.withContiguousStorageIfAvailable`` **but default implementation returns nil**
/// (see https://github.com/apple/swift-evolution/blob/main/proposals/0237-contiguous-collection.md)
public protocol BufferedCollection: Collection {
    /// Provides an access to collection inner buffer.
    /// 
    /// Don't forward to `withContiguousStorageIfAvailable` which default implementation returns nil 🤦‍♂️
    mutating func withUnsafeMutableBufferPointer<R>(_ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R) rethrows -> R
}

extension Array: BufferedCollection { }