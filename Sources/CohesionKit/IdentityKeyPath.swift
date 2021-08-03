import Combine

public struct IdentityKeyPath<Root> {
    let keyPath: AnyKeyPath
    let update: (Root, IdentityMap, ModificationStamp) -> AnyPublisher<Any, Never>

    public init<T: IdentityGraph>(_ keyPath: KeyPath<Root, T>) {
        self.keyPath = keyPath
        update = { root, identityMap, modificationId in
            identityMap
                .update(root[keyPath: keyPath], modifiedAt: modificationId)
                .map { $0 as Any }
                .eraseToAnyPublisher()
        }
    }

    public init<S: Sequence>(_ keyPath: KeyPath<Root, S>) where S.Element: IdentityGraph {
        self.keyPath = keyPath
        update = { root, identityMap, modificationId in
            identityMap
                .update(root[keyPath: keyPath], modifiedAt: modificationId)
                .map { $0 as Any }
                .eraseToAnyPublisher()
        }
    }

    public init<T: Identifiable>(_ keyPath: KeyPath<Root, T>) {
        self.keyPath = keyPath
        update = { root, identityMap, modificationId in
             identityMap
                .update(root[keyPath: keyPath], modifiedAt: modificationId)
                .map { $0 as Any }
                .eraseToAnyPublisher()
        }
    }

    public init<S: Sequence>(_ keyPath: KeyPath<Root, S>) where S.Element: Identifiable {
        self.keyPath = keyPath
        update = { root, identityMap, modificationId in

            root[keyPath: keyPath]
                .map { identityMap.update($0, modifiedAt: modificationId) }
                .combineLatest()
                .map { $0 as Any }
                .eraseToAnyPublisher()
        }
    }
}
