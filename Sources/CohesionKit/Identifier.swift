/// a unique identifier to observe an object
struct Identifier: Hashable {
    private let objectType: ObjectIdentifier
    private let key: AnyHashable

    /// Generates an identifier for type T with key as key
    init<T>(for type: T.Type, key: some Hashable) {
        self.objectType = ObjectIdentifier(type)
        self.key = AnyHashable(key)
    }

    init<T: Identifiable>(for object: T) {
        self.init(for: T.self, key: object.id)
    }

    init<T>(for type: T.Type, key: AliasKey<T>) {
        self.init(for: AliasContainer<T>.self, key: key.name)
    }
}
