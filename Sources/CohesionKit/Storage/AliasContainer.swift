
/// a container to store an aliased object
struct AliasContainer<T>: Identifiable, Aggregate {
    var id: String { key.name }

    let key: AliasKey<T>

    var content: T?
}

extension AliasContainer {
    var nestedEntitiesKeyPaths: [PartialIdentifiableKeyPath<Self>] {
        if let self = self as? AggregateKeyPathsEraser {
            return self.erasedEntitiesKeyPaths as! [PartialIdentifiableKeyPath<Self>]
        }

        if let self = self as? IdentifiableKeyPathsEraser {
            return self.erasedEntitiesKeyPaths as! [PartialIdentifiableKeyPath<Self>]
        }

        if let self = self as? CollectionAggregateKeyPathsEraser {
            return self.erasedEntitiesKeyPaths as! [PartialIdentifiableKeyPath<Self>]
        }

        if let self = self as? CollectionIdentifiableKeyPathsEraser {
            return self.erasedEntitiesKeyPaths as! [PartialIdentifiableKeyPath<Self>]
        }

        return []
    }
}

private protocol IdentifiableKeyPathsEraser {
    var erasedEntitiesKeyPaths: [Any] { get }
}

extension AliasContainer: IdentifiableKeyPathsEraser where T: Identifiable {
    var erasedEntitiesKeyPaths: [Any] {
        [PartialIdentifiableKeyPath<Self>(\.content)]
    }
}

private protocol AggregateKeyPathsEraser {
    var erasedEntitiesKeyPaths: [Any] { get }
}

extension AliasContainer: AggregateKeyPathsEraser where T: Aggregate {
    var erasedEntitiesKeyPaths: [Any] {
        [PartialIdentifiableKeyPath<Self>(\.content)]
    }
}

private protocol CollectionAggregateKeyPathsEraser {
    var erasedEntitiesKeyPaths: [Any] { get }
}

extension AliasContainer: CollectionAggregateKeyPathsEraser where T: MutableCollection, T.Element: Aggregate, T.Index: Hashable {
    var erasedEntitiesKeyPaths: [Any] {
        [PartialIdentifiableKeyPath<Self>(\.content)]
    }
}

private protocol CollectionIdentifiableKeyPathsEraser {
    var erasedEntitiesKeyPaths: [Any] { get }
}

extension AliasContainer: CollectionIdentifiableKeyPathsEraser where T: MutableCollection, T.Element: Identifiable, T.Index: Hashable {
    var erasedEntitiesKeyPaths: [Any] {
        [PartialIdentifiableKeyPath<Self>(\.content)]
    }
}