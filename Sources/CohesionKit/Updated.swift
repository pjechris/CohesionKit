import Foundation

public typealias Updater<Element> = (Updated<Element>) -> Element

/// a container with updates made on `Root`
@dynamicMemberLookup
public struct Updated<Root> {
    let root: Root
    let updates: [AnyKeyPath: Any]
    
    /// return registered update or value from root
    public subscript<T>(dynamicMember keyPath: KeyPath<Root, T>) -> T {
        get { updates[keyPath] as? T ?? root[keyPath: keyPath] }
    }
}
