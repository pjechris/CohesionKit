/// A value representing an Entity or set of Entity
public struct AliasKey<T>: Hashable {
    let name: String

    public init(named value: String) {
        self.name = value
    }
}

/// A collection of values stored on a ``SessionStore``.
///
/// To add a value to SessionStore:
/// - declare an extension on `StoreSessionValues`
/// - add a computed **instance** attribute with a default value
///
///     extension StoreSessionValues {
///         var myValue: String { "myDefaultValue" }
///     }
public struct StoreSessionValues {

}

/// Stores all values related to identity session. Those values are never released and stay in-memory until
/// you clear them
@dynamicMemberLookup
public class StoreSession {
    public subscript<T>(dynamicMember keyPath: KeyPath<StoreSessionValues, T>) -> T {
        get {
            fatalError("")
        }
    }
}