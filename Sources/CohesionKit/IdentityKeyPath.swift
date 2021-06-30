import Combine

public struct IdentityKeyPath<Root> {
    let keyPath: AnyKeyPath
    let update: (Root, AnyIdentityMap, Any) -> AnyPublisher<Any, Never>

    public init<T: IdentityGraph>(_ keyPath: KeyPath<Root, T>) {
        self.keyPath = keyPath
        update = { root, identityMap, stamp in
            identityMap
                .update(root[keyPath: keyPath], stamp: stamp)
                .map { $0 as Any }
                .eraseToAnyPublisher()
        }
    }

    public init<S: Sequence>(_ keyPath: KeyPath<Root, S>) where S.Element: IdentityGraph {
        self.keyPath = keyPath
        update = { root, identityMap, stamp in
            identityMap
                .update(root[keyPath: keyPath], stamp: stamp)
                .map { $0 as Any }
                .eraseToAnyPublisher()
        }
    }

    public init<T: Identifiable>(_ keyPath: KeyPath<Root, T>) {
        self.keyPath = keyPath
        update = { root, identityMap, stamp in
             identityMap
                .update(root[keyPath: keyPath], stamp: stamp)
                .map { $0 as Any }
                .eraseToAnyPublisher()
        }
    }

    public init<S: Sequence>(_ keyPath: KeyPath<Root, S>) where S.Element: Identifiable {
        self.keyPath = keyPath
        update = { root, identityMap, stamp in

            root[keyPath: keyPath]
                .map { identityMap.update($0, stamp: stamp) }
                .combineLatest()
                .map { $0 as Any }
                .eraseToAnyPublisher()
        }
    }
}
