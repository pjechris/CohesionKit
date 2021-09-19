
import Foundation

/// a struct containing updates made on `Root`
@dynamicMemberLookup
public struct KeyPathUpdates<Root> {
    let values: [AnyKeyPath: Any]

    public subscript<T: Relational>(dynamicMember keyPath: KeyPath<Root, T>) -> T {
        get { values[keyPath] as! T }
    }

    public subscript<T: Relational>(dynamicMember keyPath: KeyPath<Root, [T]>) -> [T] {
        get { values[keyPath] as! [T] }
    }

    public subscript<T: Identifiable>(dynamicMember keyPath: KeyPath<Root, T>) -> T {
        get { values[keyPath] as! T }
    }

    public subscript<T: Identifiable>(dynamicMember keyPath: KeyPath<Root, [T]>) -> [T] {
        get { values[keyPath] as! [T] }
    }


}
