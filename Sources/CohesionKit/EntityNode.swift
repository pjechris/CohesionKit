import Foundation
import Combine

private protocol AnyEntityNode: AnyObject {
    var value: Any { get }
}

class EntityNode<T>: AnyEntityNode {
    private typealias SubscribedChild = (unsubscribe: Unsubscription, node: AnyEntityNode)
    
    var applyChildrenChanges = true

    /// An observable entity reference
    private let ref: Ref<T>
    /// last time the ref.value was changed. Any subsequent change must have a bigger `modifiedAt` value to be applied
    private var modifiedAt: Stamp
    /// entity children
    private var children: [PartialKeyPath<T>: SubscribedChild] = [:]
    fileprivate var value: Any { ref.value }
    
    init(_ entity: T, modifiedAt: Stamp) {
        self.ref = Ref(value: entity)
        self.modifiedAt = modifiedAt
    }
    
    deinit {
        removeAllChildren()
    }
    
    func updateEntity(_ entity: T, modifiedAt newModifiedAt: Stamp) {
        guard newModifiedAt > modifiedAt else {
            return
        }
        
        modifiedAt = newModifiedAt
        ref.value = entity
    }
    
    func removeAllChildren() {
        children.values.forEach { $0.unsubscribe() }
    }
    
    func observeChild<C>(_ childNode: EntityNode<C>, for keyPath: KeyPath<T, C>) {
        if let subscribedChild = children[keyPath]?.node as? EntityNode<C>, subscribedChild == childNode {
            return
        }
        
        let unsubscription = childNode.ref.addObserver { [unowned self] newValue in
            guard self.applyChildrenChanges else {
                return
            }

            withUnsafeMutablePointer(to: &self.ref.value) {
                let pointer = UnsafeMutableRawPointer($0)
                
                pointer.assign(newValue, to: keyPath)
            }
        }
        
        children[keyPath]?.unsubscribe()
        children[keyPath] = (unsubscribe: unsubscription, node: childNode)
    }
    
    /// return each children node value mapped to its given keypath
    func childrenValues() -> [PartialKeyPath<T>: Any] {
        children.mapValues(\.node.value)
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
