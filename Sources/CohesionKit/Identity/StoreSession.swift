public typealias AliasKey<T> = KeyPath<StoreSessionValues, T>

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
    private var storage: AliasStorage = [:]
    private let defaultValues = StoreSessionValues()

    public subscript<T>(dynamicMember keyPath: KeyPath<StoreSessionValues, T>) -> T {
        get {
            storage[keyPath].value?.ref.value ?? defaultValues[keyPath: keyPath]
        }
    }
}