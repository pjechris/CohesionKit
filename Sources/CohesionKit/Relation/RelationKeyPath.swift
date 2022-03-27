import Combine

public struct PartialIdentifiableKeyPath<Root> {
    let keyPath: PartialKeyPath<Root>
    let accept: (EntityNode<Root>, Root, Stamp, IdentityVisitor) -> Void
    
    public init<T: Identifiable>(_ keyPath: KeyPath<Root, T>) {
        self.keyPath = keyPath
        self.accept = { parent, root, stamp, visitor in
            visitor.visit(
                context: EntityContext(parent: parent, keyPath: keyPath, stamp: stamp),
                entity: root[keyPath: keyPath]
            )
        }
    }
    
    public init<C: Collection>(_ keyPath: KeyPath<Root, C>) where C.Element: Identifiable, C.Index: Hashable {
        self.keyPath = keyPath
        self.accept = { parent, root, stamp, visitor in
            visitor.visit(
                context: EntityContext(parent: parent, keyPath: keyPath, stamp: stamp),
                entities: root[keyPath: keyPath]
            )
        }
    }
}

/// A `KeyPath` link between the keyPath and its `Relation`
public struct RelationKeyPath<Root> {
    let keyPath: PartialKeyPath<Root>
    /// method called when storing the element into IdentityMap
    /// we define it here in order to access the keypath exact type in `init`
    let store: (Root, IdentityStore, Stamp) -> AnyPublisher<(Any, Stamp), Never>
    
    /// Build a relation from root with an `Identifiable` child
    public init<T: Identifiable>(_ keyPath: KeyPath<Root, T>) {
        self.init(keyPath, relation: Relation.single())
    }
    
    /// Build a relation from root with a `Identifiable` sequence child
    public init<S: Sequence>(_ keyPath: KeyPath<Root, S>) where S.Element: Identifiable {
        self.init(keyPath, relation: Relation.single())
    }
    
    /// Build a relation from root with a child
    /// - Parameter relation: the object describing the child own relations
    public init<T, ID: Hashable>(_ keyPath: KeyPath<Root, T>, relation: Relation<T, ID>) {
        self.keyPath = keyPath
        store = { root, identityMap, stamp in
            identityMap
                .store(root[keyPath: keyPath], using: relation, modifiedAt: stamp)
                .map { $0 as (Any, Stamp) }
                .eraseToAnyPublisher()
        }
    }
    
    /// Build a relation from root with a sequence child
    public init<S: Sequence, ID: Hashable>(_ keyPath: KeyPath<Root, S>, relation: Relation<S.Element, ID>) {
        self.keyPath = keyPath
        store = { root, identityMap, modificationId in
            identityMap
                .store(root[keyPath: keyPath], using: relation, modifiedAt: modificationId)
                .map { $0 as (Any, Stamp) }
                .eraseToAnyPublisher()
        }
    }
}
