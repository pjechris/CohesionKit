import Combine

/// A `KeyPath` describing a `Identifiable` or `IdentityGraph` relationship on Root
public struct RelationKeyPath<Root> {
    let keyPath: AnyKeyPath
    let update: (Root, IdentityMap, Stamp) -> AnyPublisher<Any, Never>
    
    public init<T, Identity: Identifiable>(_ keyPath: KeyPath<Root, T>, relation: Relation<T, Identity>) {
        self.keyPath = keyPath
        update = { root, identityMap, stamp in
            identityMap
                .store(root[keyPath: keyPath], relation: relation, modifiedAt: stamp)
                .map { $0 as Any }
                .eraseToAnyPublisher()
        }
    }
    
    public init<T, Identity: Identifiable>(_ keyPath: KeyPath<Root, [T]>, relation: Relation<T, Identity>) {
        self.keyPath = keyPath
        update = { root, identityMap, modificationId in
            identityMap
                .store(root[keyPath: keyPath], relation: relation, modifiedAt: modificationId)
                .map { $0 as Any }
                .eraseToAnyPublisher()
        }
    }

    public init<T: Identifiable>(_ keyPath: KeyPath<Root, T>) {
        self.keyPath = keyPath
        update = { root, identityMap, modificationId in
             identityMap
                .store(root[keyPath: keyPath], modifiedAt: modificationId)
                .map { $0 as Any }
                .eraseToAnyPublisher()
        }
    }

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
}
