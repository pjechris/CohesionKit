
import Foundation

/// a struct containing updates made on `Root`
@dynamicMemberLookup
public struct KeyPathUpdates<Root> {
    let root: Root
    let updates: [AnyKeyPath: Any]
    
    /// return registered update or value from root
    public subscript<T>(dynamicMember keyPath: KeyPath<Root, T>) -> T {
        get { updates[keyPath] as? T ?? root[keyPath: keyPath] }
    }
}
