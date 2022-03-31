import Foundation
import Combine

public class IdentityMap {
    private(set) var storage: WeakStorage = WeakStorage()
    private lazy var storeVisitor = IdentityMapStoreVisitor(identityMap: self)
    
    func store<T: Identifiable>(entity: T, modifiedAt: Stamp = Date().stamp) -> EntityNode<T> {
        guard let node = storage[entity] else {
            let node = EntityNode(entity, modifiedAt: modifiedAt)
            
            storage[entity] = node
            
            return node
        }
        
        node.updateEntity(entity, modifiedAt: modifiedAt)
        
        return node
    }
    
    func store<T: Aggregate>(entity: T, modifiedAt: Stamp = Date().stamp) -> EntityNode<T> {
        let node = storage[entity] ?? EntityNode(entity, modifiedAt: modifiedAt)
        var entity = entity
        
        storage[entity] = node

        // disable changes while doing the entity update
        node.applyChildrenChanges = false
        
        // clear all children to avoid a removed child to be kept as child
        node.removeAllChildren()
        
        for keyPathContainer in entity.nestedEntitiesKeyPaths {
            keyPathContainer.accept(node, entity, modifiedAt, storeVisitor)
        }
        
        // modify the entity with (potentially) new/different child stored value than what we have
        withUnsafeMutablePointer(to: &entity) {
            let pointer = UnsafeMutableRawPointer($0)
            
            for (_, child) in node.children {
                child.selfAssignTo(pointer)
            }
        }
        
        // TODO: what about if modifiedAt is < but some of the children actually changed?
        node.updateEntity(entity, modifiedAt: modifiedAt)
        
        node.applyChildrenChanges = true

        return node
    }
    
    // TODO: try to reduce the number of updates this might trigger
    func store<C: Collection>(entities: C, modifiedAt: Stamp = Date().stamp)
    -> [EntityNode<C.Element>] where C.Element: Identifiable {
        entities.map { store(entity: $0, modifiedAt: modifiedAt) }
    }
    
    // TODO: try to reduce the number of updates this might trigger
    func store<C: Collection>(entities: C, modifiedAt: Stamp = Date().stamp)
    -> [EntityNode<C.Element>] where C.Element: Aggregate {
        entities.map { store(entity: $0, modifiedAt: modifiedAt) }
    }

}
