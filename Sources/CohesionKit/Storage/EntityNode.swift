import Foundation
import Combine

/// Typed erased protocol
protocol AnyEntityNode: AnyObject {
    var value: Any { get }
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

    var applyChildrenChanges = true
    var value: Any { ref.value }

    /// An observable entity reference
    let ref: Observable<T>
    /// last time the ref.value was changed. Any subsequent change must have a higher value to be applied
    /// if nil ref has no stamp and any change will be accepted
    private var modifiedAt: Stamp?
    /// entity children
    private(set) var children: [PartialKeyPath<T>: SubscribedChild] = [:]

    init(ref: Observable<T>, modifiedAt: Stamp?) {
        self.ref = ref
        self.modifiedAt = modifiedAt
    }

    convenience init(_ entity: T, modifiedAt: Stamp?) {
        self.init(ref: Observable(value: entity), modifiedAt: modifiedAt)
    }

    /// change the entity to a new value only if `modifiedAt` is equal than any previous registered modification
    /// - Parameter entity the new entity value
    /// - Parameter modifiedAt the new entity stamp
    func updateEntity(_ newEntity: T, modifiedAt newModifiedAt: Stamp) throws {
        if let modifiedAt, newModifiedAt <= modifiedAt  {
            throw StampError.tooOld(current: modifiedAt, received: newModifiedAt)
        }

        modifiedAt = newModifiedAt
        ref.value = newEntity
    }

    func removeAllChildren() {
        children = [:]
    }

    /// observe one of the node child
    func observeChild<C>(_ childNode: EntityNode<C>, for keyPath: KeyPath<T, C>) {
        observeChild(childNode, identity: keyPath) { pointer, newValue in
            pointer.assign(newValue, to: keyPath)
        }
    }

    /// observe a non nil child but whose keypath is represented by an Optional
    func observeChild<C>(_ childNode: EntityNode<C>, for keyPath: KeyPath<T, C?>) {
        observeChild(childNode, identity: keyPath) { pointer, newValue in
            pointer.assign(.some(newValue), to: keyPath)
        }
    }

    /// observe one of the node child whose type is a collection
    func observeChild<C: BufferedCollection>(_ childNode: EntityNode<C.Element>, for keyPath: KeyPath<T, C>, index: C.Index)
    where C.Index: Hashable {
        observeChild(childNode, identity: keyPath.appending(path: \C[index])) { pointer, newValue in
            pointer.assign(newValue, to: keyPath, index: index)
        }
    }

    /// Observe a node child
    /// - Parameter childNode: the child to observe
    /// - Parameter keyPath: a **unique** keypath associated to the child. Should have similar type but maybe a little different (optional, Array.Element, ...)
    /// - Parameter assign: to assign childNode value to current node ref value
    private func observeChild<C, Element>(
        _ childNode: EntityNode<Element>,
        identity keyPath: KeyPath<T, C>,
        update: @escaping (UnsafeMutablePointer<T>, Element) -> Void
    ) {
        if let subscribedChild = children[keyPath]?.node as? EntityNode<Element>, subscribedChild == childNode {
            return
        }

        let subscription = childNode.ref.addObserver { [unowned self] newValue in
            guard self.applyChildrenChanges else {
                return
            }

            withUnsafeMutablePointer(to: &self.ref.value) {
                update($0, newValue)
            }
        }

        children[keyPath] = SubscribedChild(subscription: subscription, node: childNode)
    }

}

extension EntityNode: Hashable {
    static func==(lhs: EntityNode<T>, rhs: EntityNode<T>) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }
}
