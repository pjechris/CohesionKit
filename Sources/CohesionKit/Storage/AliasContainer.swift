
/// a container to store an aliased object
struct AliasContainer<T>: Identifiable, Aggregate {
    var id: String { key.name }

    let key: AliasKey<T>

    var content: T
}

extension AliasContainer where T: Aggregate {
    var nestedEntitiesKeyPaths: [PartialIdentifiableKeyPath<AliasContainer<T>>] {
     [.init(\.content)]
    }
}

extension AliasContainer where T: Identifiable {
    var nestedEntitiesKeyPaths: [PartialIdentifiableKeyPath<AliasContainer<T>>] {
     [.init(\.content)]
    }
}

extension AliasContainer where T: MutableCollection, T.Element: Aggregate, T.Index: Hashable {
    var nestedEntitiesKeyPaths: [PartialIdentifiableKeyPath<AliasContainer<T>>] {
     [.init(\.content)]
    }
}

extension AliasContainer where T: MutableCollection, T.Element: Identifiable, T.Index: Hashable {
    var nestedEntitiesKeyPaths: [PartialIdentifiableKeyPath<AliasContainer<T>>] {
     [.init(\.content)]
    }
}

extension AliasContainer {
    var nestedEntitiesKeyPaths: [PartialIdentifiableKeyPath<AliasContainer<T>>] {
     []
    }
}