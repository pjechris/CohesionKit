import Combine

protocol Writable {
    func write<Value>(_ value: Value, on root: inout Any)
}

extension WritableKeyPath: Writable {
    func write<V>(_ value: V, on root: inout Any) {
        guard var rooted = root as? Root else {
            return
        }

        guard let value = value as? Value else {
            return
        }

        rooted[keyPath: self] = value
        root = rooted
    }
}

/// A `KeyPath` wrapper allowing only `Identifiable`/`Aggregate` keypaths
public struct PartialIdentifiableKeyPath<Root> {
    let keyPath: PartialKeyPath<Root>
    let accept: (EntityNode<Root>, Root, Stamp?, NestedEntitiesVisitor) -> Void
    let store: (Root, Stamp?, EntityStore) -> [PartialKeyPath<Root>: ObjectKey]

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

            return [keyPath: entityID]
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

            return [keyPath: entityID]
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

                return [keyPath.unwrapped(): entityID]
            }

            return [:]
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

                return [keyPath.unwrapped(): entityID]
            }

            return [:]
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
            let keysAndValues = root[keyPath: keyPath].indices.map { index in
                let entity = root[keyPath: keyPath][index]
                let entityID = ObjectKey(of: C.Element.self, id: entity.id)

                store.store(entity, identifier: entityID, modifiedAt: stamp)

                return (keyPath.appending(path: \.[index]), entityID)
            }

            return Dictionary(keysAndValues) { first, second in
                print("BUG: Got duplicate keypath for collection!")
                return second
            }
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
                let keysAndValues = entities.indices.map { index in
                    let entity = entities[index]
                    let entityID = ObjectKey(of: C.Element.self, id: entity.id)

                    store.store(entity, identifier: entityID, modifiedAt: stamp)

                    return (keyPath.unwrapped().appending(path: \.[index]), entityID)
                }

                return Dictionary(keysAndValues) { first, second in
                    print("BUG: Got duplicate keypath for collection!")
                    return second
                }
            }

            return [:]
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
            let keysAndValues = root[keyPath: keyPath].indices.map { index in
                let entity = root[keyPath: keyPath][index]
                let entityID = ObjectKey(of: C.Element.self, id: entity.id)

                store.store(entity, identifier: entityID, modifiedAt: stamp)

                return (keyPath.appending(path: \.[index]), entityID)
            }

            return Dictionary(keysAndValues) { first, second in
                print("BUG: Got duplicate keypath for collection!")
                return second
            }
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
                let keysAndValues = entities.indices.map { index in
                    let entity = entities[index]
                    let entityID = ObjectKey(of: C.Element.self, id: entity.id)

                    store.store(entity, identifier: entityID, modifiedAt: stamp)

                    return (keyPath.unwrapped().appending(path: \.[index]), entityID)
                }

                return Dictionary(keysAndValues) { first, second in
                    print("BUG: Got duplicate keypath for collection!")
                    return second
                }
            }

            return [:]
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
            var refs: [PartialKeyPath<Root>: ObjectKey] = [:]

            for wrappedKeyPath in root[keyPath: keyPath].wrappedEntitiesKeyPaths(relativeTo: keyPath) {
                refs.merge(wrappedKeyPath.store(root, stamp, store)) { first, second in
                    print("BUG: duplicate keyPath in EntityWrapper!")
                    return second
                }
            }

            return refs
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
            var refs: [PartialKeyPath<Root>: ObjectKey] = [:]

            if let wrapper = root[keyPath: keyPath] {
                for wrappedKeyPath in wrapper.wrappedEntitiesKeyPaths(relativeTo: keyPath.unwrapped()) {
                    refs.merge(wrappedKeyPath.store(root, stamp, store)) { first, second in
                        print("BUG: duplicate keyPath in EntityWrapper!")
                        return second
                    }
                }
            }

            return refs
        }
    }
}

private extension WritableKeyPath {
    func unwrapped<Wrapped>() -> WritableKeyPath<Root, Wrapped> where Value == Optional<Wrapped> {
        self.appending(path: \.self!)
    }
}
