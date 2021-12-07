import Foundation

/// a function transforming `Updated<Element>` into `Element`
public typealias Updater<Element> = (Updated<Element>) -> Element

/// A container with updates made on `Root`
///
/// You can access updates using `Root` member names: `Updated<User>(..).username`
@dynamicMemberLookup
public struct Updated<Root> {
    let root: Root
    let updates: [AnyKeyPath: Any]
    
    /// return registered update or value from root
    public subscript<T>(dynamicMember keyPath: KeyPath<Root, T>) -> T {
        get { updates[keyPath] as? T ?? root[keyPath: keyPath] }
    }
}
