import Combine

/// A `KeyPath` wrapper allowing only `Identifiable`/`Aggregate` keypaths
public struct PartialIdentifiableKeyPath<Root> {
    let keyPath: PartialKeyPath<Root>
    let accept: (EntityNode<Root>, Root, Stamp, NestedEntitiesVisitor) -> Void
    
    public init<T: Identifiable>(_ keyPath: KeyPath<Root, T>) {
        self.keyPath = keyPath
        self.accept = { parent, root, stamp, visitor in
            visitor.visit(
                context: EntityContext(parent: parent, keyPath: keyPath, stamp: stamp),
                entity: root[keyPath: keyPath]
            )
        }
    }
    
    public init<T: Aggregate>(_ keyPath: KeyPath<Root, T>) {
        self.keyPath = keyPath
        self.accept = { parent, root, stamp, visitor in
            visitor.visit(
                context: EntityContext(parent: parent, keyPath: keyPath, stamp: stamp),
                entity: root[keyPath: keyPath]
            )
        }
    }
    
    public init<T: Identifiable>(_ keyPath: KeyPath<Root, T?>) {
        self.keyPath = keyPath
        self.accept = { parent, root, stamp, visitor in
            visitor.visit(
                context: EntityContext(parent: parent, keyPath: keyPath, stamp: stamp),
                entity: root[keyPath: keyPath]
            )
        }
    }
    
    public init<T: Aggregate>(_ keyPath: KeyPath<Root, T?>) {
        self.keyPath = keyPath
        self.accept = { parent, root, stamp, visitor in
            visitor.visit(
                context: EntityContext(parent: parent, keyPath: keyPath, stamp: stamp),
                entity: root[keyPath: keyPath]
            )
        }
    }
    
    public init<C: BufferedCollection>(_ keyPath: KeyPath<Root, C>) where C.Element: Identifiable, C.Index: Hashable {
        self.keyPath = keyPath
        self.accept = { parent, root, stamp, visitor in
            visitor.visit(
                context: EntityContext(parent: parent, keyPath: keyPath, stamp: stamp),
                entities: root[keyPath: keyPath]
            )
        }
    }
    
    public init<C: BufferedCollection>(_ keyPath: KeyPath<Root, C>) where C.Element: Aggregate, C.Index: Hashable {
        self.keyPath = keyPath
        self.accept = { parent, root, stamp, visitor in
            visitor.visit(
                context: EntityContext(parent: parent, keyPath: keyPath, stamp: stamp),
                entities: root[keyPath: keyPath]
            )
        }
    }
}