import Foundation
import Combine

/// Typed erased protocol
protocol AnyEntityNode: AnyObject {
    var value: Any { get }
}

/// A type registering observers on a given entity
public struct EntityObserver<T> {
    let node: EntityNode<T>
    /// the value at the time the observer was created. If you want **realtime** value use `observe to get notified of changes
    public let value: T
    
    init(node: EntityNode<T>) {
        self.node = node
        self.value = node.value as! T
    }
    
    /// Add an observer being notified when entity change
    /// - Parameter onChange: a closure called when value changed
    /// - Returns: a subscription to cancel observation. Observation is automatically cancelled if subscription is deinit.
    /// As long as the subscription is alived the entity is kept in the IdentityMap.
    func observe(_ onChange: @escaping (T) -> Void) -> Subscription {
        let subscription = node.ref.addObserver(onChange)
        let retain = Unmanaged.passRetained(node)
        
        return Subscription {
            subscription.unsubscribe()
            retain.release()
        }
    }
}

/// A graph node representing a entity of type `T` and its children. Anytime one of its children is updated the node
/// will reflect the change on its own value.
class EntityNode<T>: AnyEntityNode {    
    var applyChildrenChanges = true
    var value: Any { ref.value }
    
    /// An observable entity reference
    fileprivate let ref: Ref<T>
    /// last time the ref.value was changed. Any subsequent change must have a bigger `modifiedAt` value to be applied
    private var modifiedAt: Stamp
    /// entity children
    private(set) var children: [PartialKeyPath<T>: SubscribedChild] = [:]
    
    init(ref: Ref<T>, modifiedAt: Stamp) {
        self.ref = ref
        self.modifiedAt = modifiedAt
    }
    
    convenience init(_ entity: T, modifiedAt: Stamp) {
        self.init(ref: Ref(value: entity), modifiedAt: modifiedAt)
    }
    
    /// change the entity to a new value only if `modifiedAt` is equal or higher than any registered previous modification
    func updateEntity(_ entity: T, modifiedAt newModifiedAt: Stamp) {
        guard newModifiedAt >= modifiedAt else {
            return
        }
        
        modifiedAt = newModifiedAt
        ref.value = entity
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
    where C.Index == Int {
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
        assign: @escaping (UnsafeMutableRawPointer, Element) -> Void
    ) {
        if let subscribedChild = children[keyPath]?.node as? EntityNode<Element>, subscribedChild == childNode {
            return
        }
        
        let subscription = childNode.ref.addObserver { [unowned self] newValue in
            guard self.applyChildrenChanges else {
                return
            }

            withUnsafeMutablePointer(to: &self.ref.value) {
                let pointer = UnsafeMutableRawPointer($0)
                
                assign(pointer, newValue)
            }
        }
        
        children[keyPath] = SubscribedChild(
            subscription: subscription,
            node: childNode,
            selfAssignTo: { assign($0, childNode.ref.value) }
        )
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
