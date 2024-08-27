import Foundation
import Combine

struct EntityMetadata {
    /// children this entity is referencing/using
    /// key: the children keypath in the parent, value: the key in EntitieStorage
    // TODO: change value to a ObjectKey
    var childrenRefs: [AnyKeyPath: String] = [:]

    /// parents referencing this entity. This means this entity should be listed inside its parents `EntityMetadata.childrenRefs` attribute
    var parentsRefs: Set<ObjectKey> = []
    /// alias referencing this entity
    var aliasesRefs: Set<String> = []

    /// number of observers
    var observersCount: Int = 0

    var isActivelyUsed: Bool {
        observersCount > 0 || !parentsRefs.isEmpty || !aliasesRefs.isEmpty
    }
}

/// Typed erased protocol
protocol AnyEntityNode: AnyObject {
    var value: Any { get }
    var metadata: EntityMetadata { get }

    func nullify()
}

/// A graph node representing a entity of type `T` and its children. Anytime one of its children is updated the node
/// will reflect the change on its own value.
class EntityNode<T>: AnyEntityNode {
    /// A child subscription used by its EntityNode parent
    struct SubscribedChild {
        /// the child subscription. Use it to unsubscribe to child upates
        let subscription: Subscription
        /// the child node value
        let node: AnyEntityNode
    }

    var value: Any { ref.value }

    var metadata = EntityMetadata()

    var applyChildrenChanges = true
    /// An observable entity reference
    let ref: Observable<T>

    let storageKey: String

    private let onChange: ((EntityNode<T>) -> Void)?
    /// last time the ref.value was changed. Any subsequent change must have a higher value to be applied
    /// if nil ref has no stamp and any change will be accepted
    private var modifiedAt: Stamp?
    /// entity children
    private(set) var children: [PartialKeyPath<T>: SubscribedChild] = [:]

    init(ref: Observable<T>, key: String, modifiedAt: Stamp?, onChange: ((EntityNode<T>) -> Void)? = nil) {
        self.ref = ref
        self.modifiedAt = modifiedAt
        self.onChange = onChange
        self.storageKey = key
    }

    convenience init(_ entity: T, key: String, modifiedAt: Stamp?, onChange: ((EntityNode<T>) -> Void)? = nil) {
        self.init(ref: Observable(value: entity), key: key, modifiedAt: modifiedAt, onChange: onChange)
    }

    convenience init(_ entity: T, modifiedAt: Stamp?, onChange: ((EntityNode<T>) -> Void)? = nil) where T: Identifiable {
        let key = "\(T.self)-\(entity.id)"
        self.init(entity, key: key, modifiedAt: modifiedAt, onChange: onChange)
    }

    /// change the entity to a new value. If modifiedAt is nil or > to previous date update the value will be changed
    /// - Parameter entity the new entity value
    /// - Parameter modifiedAt the new entity stamp
    func updateEntity(_ newEntity: T, modifiedAt newModifiedAt: Stamp?) throws {
        if let newModifiedAt, let modifiedAt, newModifiedAt <= modifiedAt  {
            throw StampError.tooOld(current: modifiedAt, received: newModifiedAt)
        }

        modifiedAt = newModifiedAt ?? modifiedAt
        ref.value = newEntity
        onChange?(self)
    }

    func nullify() {
        if let value = ref.value as? Nullable {
            try? updateEntity(value.nullified() as! T, modifiedAt: nil)
        }
    }

    func removeAllChildren() {
        children = [:]
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
        if let subscribedChild = children[keyPath]?.node as? EntityNode<Element>, subscribedChild == childNode {
            return
        }

        let subscription = childNode.ref.addObserver { [unowned self] newValue in
            guard self.applyChildrenChanges else {
                return
            }

            update(&self.ref.value, newValue)
            self.onChange?(self)
        }

        children[keyPath] = SubscribedChild(subscription: subscription, node: childNode)
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
