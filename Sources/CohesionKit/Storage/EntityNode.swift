import Foundation
import Combine

struct EntityMetadata {
    /// children this entity is referencing/using
    var childrenRefs: [Identifier: AnyKeyPath] = [:]

    /// parents referencing this entity. This means this entity should be listed inside its parents `EntityMetadata.childrenRefs` attribute
    var parentsRefs: Set<Identifier> = []
    /// alias referencing this entity
    var aliasesRefs: Set<Identifier> = []

    /// number of observers
    var observersCount: Int = 0

    var isActivelyUsed: Bool {
        observersCount > 0 || !parentsRefs.isEmpty || !aliasesRefs.isEmpty
    }
}

/// Typed erased protocol
protocol AnyEntityNode: AnyObject {
    associatedtype Value

    /// a unique identifier that should represent this node
    var id: Identifier { get }
    var value: Value { get }
    var metadata: EntityMetadata { get }

    func nullify() -> Bool
    func removeParent(_ node: any AnyEntityNode)
    func updateEntityRelationship(_ child: some AnyEntityNode)
    func enqueue(in: ObserverRegistry)
}

/// A graph node representing a entity of type `T` and its children. Anytime one of its children is updated the node
/// will reflect the change on its own value.
class EntityNode<T>: AnyEntityNode {
    typealias Value = T
    /// A child subscription used by its EntityNode parent
    struct SubscribedChild {
        /// the child subscription. Use it to unsubscribe to child upates
        let subscription: Subscription
        /// the child node value
        let node: any AnyEntityNode
    }

    private(set) var value: Value

    var metadata = EntityMetadata()
    // FIXME: to delete, it's "just" to have a strong ref and avoid nodes to be deleted. Need a better memory management
    private var childrenNodes: [any AnyEntityNode] = []

    var applyChildrenChanges = true

    let id: Identifier

    /// last time `value` was changed. Any subsequent change must have a higher value to be applied
    /// if nil ref has no stamp and any change will be accepted
    private var modifiedAt: Stamp?
    /// entity children
    private(set) var children: [PartialKeyPath<T>: SubscribedChild] = [:]

    init(_ entity: T, id: Identifier, modifiedAt: Stamp?) {
      self.value = entity
      self.modifiedAt = modifiedAt
      self.id = id
    }

    convenience init(_ entity: T, modifiedAt: Stamp?) where T: Identifiable {
      self.init(entity, id: Identifier(for: entity), modifiedAt: modifiedAt)
    }

    /// change the entity to a new value. If modifiedAt is nil or > to previous date update the value will be changed
    /// - Parameter entity the new entity value
    /// - Parameter modifiedAt the new entity stamp
    func updateEntity(_ newEntity: T, modifiedAt newModifiedAt: Stamp?) throws {
        if let newModifiedAt, let modifiedAt, newModifiedAt <= modifiedAt  {
            throw StampError.tooOld(current: modifiedAt, received: newModifiedAt)
        }

        modifiedAt = newModifiedAt ?? modifiedAt
        value = newEntity
    }

    func nullify() -> Bool {
        if let value = value as? Nullable {
            do {
                try updateEntity(value.nullified() as! T, modifiedAt: nil)
                return true
            }
            catch {
                return false
            }
        }

        return false
    }

    func removeAllChildren() {
        children = [:]
        metadata.childrenRefs = [:]
        childrenNodes = []
    }

    func removeParent(_ node: any AnyEntityNode) {
        metadata.parentsRefs.remove(node.id)
    }

    func updateEntityRelationship<U: AnyEntityNode>(_ child: U) {
        guard applyChildrenChanges else {
            return
        }

        guard let keyPath = metadata.childrenRefs[child.id] else {
            return
        }

        if let writableKeyPath = keyPath as? WritableKeyPath<T, U.Value> {
            value[keyPath: writableKeyPath] = child.value
            return
        }

        if let optionalWritableKeyPath = keyPath as? WritableKeyPath<T, U.Value?> {
            value[keyPath: optionalWritableKeyPath] = child.value
            return
        }

        print("CohesionKit: cannot convert \(type(of: keyPath)) to WritableKeyPath<\(T.self), \(U.Value.self)>")
    }

    func enqueue(in registry: ObserverRegistry) {
        registry.enqueueChange(for: self)
    }

    /// observe one of the node child
    func observeChild<C>(_ childNode: EntityNode<C>, for keyPath: WritableKeyPath<T, C>) {
        observeChild(childNode, identity: keyPath) { root, newValue in
            root[keyPath: keyPath] = newValue
        }
    }

    /// observe a non nil child but whose keypath is represented by an Optional
    func observeChild<C>(_ childNode: EntityNode<C>, for keyPath: WritableKeyPath<T, C?>) {
        observeChild(childNode, identity: keyPath) { root, newValue in
            root[keyPath: keyPath] = .some(newValue)
        }
    }

    /// Observe a node child
    /// - Parameter childNode: the child to observe
    /// - Parameter keyPath: a **unique** keypath associated to the child. Should have similar type but maybe a little different (optional)
    /// - Parameter assign: to assign childNode value to current node ref value
    private func observeChild<C, Element>(
        _ childNode: EntityNode<Element>,
        identity keyPath: KeyPath<T, C>,
        update: @escaping (inout T, Element) -> Void
    ) {
        metadata.childrenRefs[childNode.id] = keyPath
        childNode.metadata.parentsRefs.insert(id)
        childrenNodes.append(childNode)
    }
}

extension EntityNode: Hashable {
    static func==(lhs: EntityNode<T>, rhs: EntityNode<T>) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
