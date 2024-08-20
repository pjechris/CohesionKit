import Combine

/// A `KeyPath` wrapper allowing only `Identifiable`/`Aggregate` keypaths
public struct PartialIdentifiableKeyPath<Root> {
    let keyPath: PartialKeyPath<Root>
    let accept: (EntityNode<Root>, Root, Stamp?, NestedEntitiesVisitor) -> Void
    let store: (Root, Stamp?, EntityStore) -> Set<ObjectKey>

    /// Creates an instance referencing an `Identifiable` keyPath
    public init<T: Identifiable>(_ keyPath: WritableKeyPath<Root, T>) {
        self.keyPath = keyPath
        self.accept = { parent, root, stamp, visitor in
            visitor.visit(
                context: EntityContext(parent: parent, keyPath: keyPath, stamp: stamp),
                entity: root[keyPath: keyPath]
            )
        }
        self.store = { root, stamp, store in
            let entity = root[keyPath: keyPath]
            let entityID = ObjectKey(of: T.self, id: entity.id)

            store.store(entity, identifier: entityID, modifiedAt: stamp)

            return [entityID]
        }
    }

    /// Creates an instance referencing an `Aggregate` keyPath
    public init<T: Aggregate>(_ keyPath: WritableKeyPath<Root, T>) {
        self.keyPath = keyPath
        self.accept = { parent, root, stamp, visitor in
            visitor.visit(
                context: EntityContext(parent: parent, keyPath: keyPath, stamp: stamp),
                entity: root[keyPath: keyPath]
            )
        }
        self.store = { root, stamp, store in
            let entity = root[keyPath: keyPath]
            let entityID = ObjectKey(of: T.self, id: entity.id)

            store.store(entity, identifier: entityID, modifiedAt: stamp)

            return [entityID]
        }
    }

    /// Creates an instance referencing an optional `Identifiable` keyPath
    public init<T: Identifiable>(_ keyPath: WritableKeyPath<Root, T?>) {
        self.keyPath = keyPath
        self.accept = { parent, root, stamp, visitor in
            visitor.visit(
                context: EntityContext(parent: parent, keyPath: keyPath, stamp: stamp),
                entity: root[keyPath: keyPath]
            )
        }
        self.store = { root, stamp, store in
            if let entity = root[keyPath: keyPath] {
                let entityID = ObjectKey(of: T.self, id: entity.id)

                store.store(entity, identifier: entityID, modifiedAt: stamp)

                return [entityID]
            }

            return []
        }
    }

    public init<T: Aggregate>(_ keyPath: WritableKeyPath<Root, T?>) {
        self.keyPath = keyPath
        self.accept = { parent, root, stamp, visitor in
            visitor.visit(
                context: EntityContext(parent: parent, keyPath: keyPath, stamp: stamp),
                entity: root[keyPath: keyPath]
            )
        }
        self.store = { root, stamp, store in
            if let entity = root[keyPath: keyPath] {
                let entityID = ObjectKey(of: T.self, id: entity.id)

                store.store(entity, identifier: entityID, modifiedAt: stamp)

                return [entityID]
            }

            return []
        }
    }

    public init<C: MutableCollection>(_ keyPath: WritableKeyPath<Root, C>) where C.Element: Identifiable, C.Index: Hashable {
        self.keyPath = keyPath
        self.accept = { parent, root, stamp, visitor in
            visitor.visit(
                context: EntityContext(parent: parent, keyPath: keyPath, stamp: stamp),
                entities: root[keyPath: keyPath]
            )
        }
        self.store = { root, stamp, store in
            Set(
                root[keyPath: keyPath].map { entity in
                    let entityID = ObjectKey(of: C.Element.self, id: entity.id)

                    store.store(entity, identifier: entityID, modifiedAt: stamp)

                    return entityID
                }
            )
        }
    }

    public init<C: MutableCollection>(_ keyPath: WritableKeyPath<Root, C?>) where C.Element: Identifiable, C.Index: Hashable {
        self.keyPath = keyPath
        self.accept = { parent, root, stamp, visitor in
            if let entities = root[keyPath: keyPath] {
                visitor.visit(
                    context: EntityContext(parent: parent, keyPath: keyPath.unwrapped(), stamp: stamp),
                    entities: entities
                )
            }
        }
        self.store = { root, stamp, store in
            if let entities = root[keyPath: keyPath] {
                return Set(
                    entities.map { entity in
                        let entityID = ObjectKey(of: C.Element.self, id: entity.id)

                        store.store(entity, identifier: entityID, modifiedAt: stamp)

                        return entityID
                    }
                )
            }

            return []
        }
    }

    public init<C: MutableCollection>(_ keyPath: WritableKeyPath<Root, C>) where C.Element: Aggregate, C.Index: Hashable {
        self.keyPath = keyPath
        self.accept = { parent, root, stamp, visitor in
            visitor.visit(
                context: EntityContext(parent: parent, keyPath: keyPath, stamp: stamp),
                entities: root[keyPath: keyPath]
            )
        }
        self.store = { root, stamp, store in
            Set(
                root[keyPath: keyPath].map { entity in
                    let entityID = ObjectKey(of: C.Element.self, id: entity.id)

                    store.store(entity, identifier: entityID, modifiedAt: stamp)

                    return entityID
                }
            )
        }
    }

    public init<C: MutableCollection>(_ keyPath: WritableKeyPath<Root, C?>) where C.Element: Aggregate, C.Index: Hashable {
        self.keyPath = keyPath
        self.accept = { parent, root, stamp, visitor in
            if let entities = root[keyPath: keyPath] {
                visitor.visit(
                    context: EntityContext(parent: parent, keyPath: keyPath.unwrapped(), stamp: stamp),
                    entities: entities
                )
            }
        }
        self.store = { root, stamp, store in
            if let entities = root[keyPath: keyPath] {
                return Set(
                    entities.map { entity in
                        let entityID = ObjectKey(of: C.Element.self, id: entity.id)

                        store.store(entity, identifier: entityID, modifiedAt: stamp)

                        return entityID
                    }
                )
            }

            return []
        }
    }

    public init<W: EntityWrapper>(wrapper keyPath: WritableKeyPath<Root, W>) {
        self.keyPath = keyPath
        self.accept = { parent, root, stamp, visitor in
            for wrappedKeyPath in root[keyPath: keyPath].wrappedEntitiesKeyPaths(relativeTo: keyPath) {
                wrappedKeyPath.accept(parent, root, stamp, visitor)
            }
        }
        self.store = {  root, stamp, store in
            var refs: [ObjectKey] = []

            for wrappedKeyPath in root[keyPath: keyPath].wrappedEntitiesKeyPaths(relativeTo: keyPath) {
                refs.append(contentsOf: wrappedKeyPath.store(root, stamp, store))
            }

            return Set(refs)
        }
    }

    public init<W: EntityWrapper>(wrapper keyPath: WritableKeyPath<Root, W?>) {
        self.keyPath = keyPath
        self.accept = { parent, root, stamp, visitor in
            if let wrapper = root[keyPath: keyPath] {
                for wrappedKeyPath in wrapper.wrappedEntitiesKeyPaths(relativeTo: keyPath.unwrapped()) {
                    wrappedKeyPath.accept(parent, root, stamp, visitor)
                }
            }
        }
        self.store = {  root, stamp, store in
            var refs: [ObjectKey] = []

            if let wrapper = root[keyPath: keyPath] {
                for wrappedKeyPath in wrapper.wrappedEntitiesKeyPaths(relativeTo: keyPath.unwrapped()) {
                    refs.append(contentsOf: wrappedKeyPath.store(root, stamp, store))
                }
            }

            return Set(refs)
        }
    }
}

private extension WritableKeyPath {
    func unwrapped<Wrapped>() -> WritableKeyPath<Root, Wrapped> where Value == Optional<Wrapped> {
        self.appending(path: \.self!)
    }
}
