import Combine

/// A `KeyPath` describing a `Identifiable` or `IdentityGraph` relationship on Root
public struct RelationKeyPath<Root> {
    let keyPath: AnyKeyPath
    let update: (Root, IdentityMap, Stamp) -> AnyPublisher<Any, Never>
    
    /// Build a relation from root with an `Identifiable` child
    public init<T: Identifiable>(_ keyPath: KeyPath<Root, T>) {
        self.keyPath = keyPath
        update = { root, identityMap, modificationId in
            identityMap
                .store(root[keyPath: keyPath], modifiedAt: modificationId)
                .map { $0 as Any }
                .eraseToAnyPublisher()
        }
    }
    
    /// Build a relation from root with a child
    /// - Parameter relation: the object describing the child own relations
    public init<T, Identity: Identifiable>(_ keyPath: KeyPath<Root, T>, relation: Relation<T, Identity>) {
        self.keyPath = keyPath
        update = { root, identityMap, stamp in
            identityMap
                .store(root[keyPath: keyPath], relation: relation, modifiedAt: stamp)
                .map { $0 as Any }
                .eraseToAnyPublisher()
        }
    }
    
    /// Build a relation from root with a `Identifiable` sequence child
    public init<S: Sequence>(_ keyPath: KeyPath<Root, S>) where S.Element: Identifiable {
        self.keyPath = keyPath
        update = { root, identityMap, modificationId in
            root[keyPath: keyPath]
                .map { identityMap.store($0, modifiedAt: modificationId) }
                .combineLatest()
                .map { $0 as Any }
                .eraseToAnyPublisher()
        }
    }
    
    /// Build a relation from root with a sequence child
    public init<S: Sequence, Identity: Identifiable>(_ keyPath: KeyPath<Root, S>, relation: Relation<S.Element, Identity>) {
        self.keyPath = keyPath
        update = { root, identityMap, modificationId in
            identityMap
                .store(root[keyPath: keyPath], relation: relation, modifiedAt: modificationId)
                .map { $0 as Any }
                .eraseToAnyPublisher()
        }
    }
}
