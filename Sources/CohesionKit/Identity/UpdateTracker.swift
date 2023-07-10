/// a type tracking actively if an entity has changes
public struct UpdateTracker<T> {
    /// the entity value. Changes are applied to it
    private(set) var entity: T
    /// nested entities having an active change
    private(set) var nestedEntitiesChanged: Set<PartialKeyPath<T>> = []
    /// true if any property in entity changed
    private(set) var hasChanges = false

    /// Get or set a property of the tracked entity.
    ///
    /// If `Value` conforms to `Equatable`, changes will be applied only if `newValue` differs from current one.
    public subscript<Value>(dynamicMember keyPath: WritableKeyPath<T, Value>) -> Value {
        get { entity[keyPath: keyPath] }
        set { set(newValue, to: keyPath) }
    }

    /// Get or set an optional `Identifiable` property of the tracked entity.
    ///
    /// If `Value` conforms to `Equatable`, changes will be applied only if `newValue` differs from current one.
    public subscript<Value: Identifiable>(dynamicMember keyPath: WritableKeyPath<T, Value?>) -> Value? {
        get { entity[keyPath: keyPath] }
        set {
            if set(newValue, to: keyPath) {
                nestedEntitiesChanged.insert(keyPath)
            }
        }
    }

    /// Get or set an `Identifiable` property of the tracked entity.
    ///
    /// If `Value` conforms to `Equatable`, changes will be applied only if `newValue` differs from current one.
    public subscript<Value: Identifiable>(dynamicMember keyPath: WritableKeyPath<T, Value>) -> Value {
        get { entity[keyPath: keyPath] }
        set {
            if set(newValue, to: keyPath) {
                nestedEntitiesChanged.insert(keyPath)
            }
        }
    }

    /// Get or set a `Identifiable` collection property of the tracked entity.
    ///
    /// If `Value` conforms to `Equatable`, changes will be applied only if `newValue` differs from current one.
    public subscript<Value: Collection>(dynamicMember keyPath: WritableKeyPath<T, Value>) -> Value
    where Value.Element: Identifiable, Value.Index: Hashable {
        get { entity[keyPath: keyPath] }
        set {
            if set(newValue, to: keyPath) {
                nestedEntitiesChanged.insert(keyPath)
            }
        }
    }

    /// Use this function if you can't set a value using dynamic member lookup.
    ///
    /// If `Value` conforms to `Equatable`, changes will be applied only if `newValue` differs from current one.
    @discardableResult
    public mutating func `set`<Value>(_ newValue: Value, to keyPath: WritableKeyPath<T, Value>) -> Bool {
        if let value = entity[keyPath: keyPath] as? any Equatable, value.isEqual(newValue) {
            return false
        }

        entity[keyPath: keyPath] = newValue
        hasChanges = true

        return true
    }
}

extension Equatable {
    func isEqual<T>(_ rhs: T) -> Bool {
        guard let rhs = rhs as? Self else {
            return false
        }

        return self == rhs
    }
}