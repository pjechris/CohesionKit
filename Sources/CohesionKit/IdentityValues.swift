
import Foundation

@dynamicMemberLookup
public struct IdentityValues<Root> {
    let values: [AnyKeyPath: Any]

    public subscript<T: IdentityGraph>(dynamicMember keyPath: KeyPath<Root, T>) -> T {
        get { values[keyPath] as! T }
    }

    public subscript<T: Identifiable>(dynamicMember keyPath: KeyPath<Root, T>) -> T {
        get { values[keyPath] as! T }
    }

    public subscript<T: Identifiable>(dynamicMember keyPath: KeyPath<Root, [T]>) -> [T] {
        get { values[keyPath] as! [T] }
    }


}
