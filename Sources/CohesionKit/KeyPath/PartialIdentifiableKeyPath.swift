import Combine

/// A `KeyPath` wrapper allowing only `Identifiable`/`Aggregate` keypaths
public struct PartialIdentifiableKeyPath<Root> {
    let keyPath: PartialKeyPath<Root>
    let accept: (EntityNode<Root>, Root, Stamp, NestedEntitiesVisitor) -> Void

    /// Creates an instance referencing an `Identifiable` keyPath
    public init<T: Identifiable>(_ keyPath: WritableKeyPath<Root, T>) {
        self.keyPath = keyPath
        self.accept = { parent, root, stamp, visitor in
            visitor.visit(
                context: EntityContext(parent: parent, keyPath: keyPath, stamp: stamp),
                entity: root[keyPath: keyPath]
            )
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
    }

    public init<T: Aggregate>(_ keyPath: WritableKeyPath<Root, T?>) {
        self.keyPath = keyPath
        self.accept = { parent, root, stamp, visitor in
            visitor.visit(
                context: EntityContext(parent: parent, keyPath: keyPath, stamp: stamp),
                entity: root[keyPath: keyPath]
            )
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
    }

    public init<C: MutableCollection>(_ keyPath: WritableKeyPath<Root, C>) where C.Element: Aggregate, C.Index: Hashable {
        self.keyPath = keyPath
        self.accept = { parent, root, stamp, visitor in
            visitor.visit(
                context: EntityContext(parent: parent, keyPath: keyPath, stamp: stamp),
                entities: root[keyPath: keyPath]
            )
        }
    }

    public init<W: EntityEnumWrapper>(wrapper keyPath: WritableKeyPath<Root, W>) {
        self.keyPath = keyPath
        self.accept = { (parent: EntityNode<Root>, root: Root, stamp: Stamp, visitor: NestedEntitiesVisitor) in
            for wrappedKeyPath in root[keyPath: keyPath].wrappedEntitiesKeyPaths(for: keyPath) {
                wrappedKeyPath.accept(parent, root, stamp, visitor)
            }
        }
    }

    public init<W: EntityEnumWrapper>(wrapper keyPath: WritableKeyPath<Root, W?>) {
        self.keyPath = keyPath
        self.accept = { (parent: EntityNode<Root>, root: Root, stamp: Stamp, visitor: NestedEntitiesVisitor) in
            if let wrapper = root[keyPath: keyPath] {
                for wrappedKeyPath in wrapper.wrappedEntitiesKeyPaths(for: keyPath.unwrapped()) {
                    wrappedKeyPath.accept(parent, root, stamp, visitor)
                }
            }
        }
    }
}

private extension WritableKeyPath {
    func unwrapped<Wrapped>() -> WritableKeyPath<Root, Wrapped> where Value == Optional<Wrapped> {
        self.appending(path: \.self!)
    }
}