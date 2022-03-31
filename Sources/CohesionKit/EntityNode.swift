import Foundation
import Combine

protocol AnyEntityNode: AnyObject {
    var value: Any { get }
}

class EntityNode<T>: AnyEntityNode {
    private typealias SubscribedChild = (subscription: Subscription, node: AnyEntityNode)
    
    var applyChildrenChanges = true
    var value: Any { ref.value }
    
    /// An observable entity reference
    private let ref: Ref<T>
    /// last time the ref.value was changed. Any subsequent change must have a bigger `modifiedAt` value to be applied
    private var modifiedAt: Stamp
    /// entity children
    private var children: [PartialKeyPath<T>: SubscribedChild] = [:]
    
    init(ref: Ref<T>, modifiedAt: Stamp) {
        self.ref = ref
        self.modifiedAt = modifiedAt
    }
    
    convenience init(_ entity: T, modifiedAt: Stamp) {
        self.init(ref: Ref(value: entity), modifiedAt: modifiedAt)
    }
    
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
    
    func observeChild<C>(_ childNode: EntityNode<C>, for keyPath: KeyPath<T, C>) {
        observeChild(childNode, for: keyPath) { pointer, newValue in
            pointer.assign(newValue, to: keyPath)
        }
    }
    
    func observeChild<C: BufferedCollection>(_ childNode: EntityNode<C.Element>, for keyPath: KeyPath<T, C>, index: C.Index)
    where C.Index == Int {
        observeChild(childNode, for: keyPath) { pointer, newValue in
            pointer.assign(newValue, to: keyPath, index: index)
        }
    }
    
    /// return each children node value mapped to its given keypath
    func childrenValues() -> [PartialKeyPath<T>: Any] {
        children.mapValues(\.node.value)
    }
    
    private func observeChild<C, Element>(
        _ childNode: EntityNode<Element>,
        for keyPath: KeyPath<T, C>,
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
        
        children[keyPath] = (subscription: subscription, node: childNode)
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
