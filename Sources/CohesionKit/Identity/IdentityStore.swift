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

        // TODO: if this entity is already observed, each child change will trigger an update
        // we need to merge or (disable them?) while doing the entity update
        node.applyChildrenChanges = false
        
        // TODO: What about if some observers should stop? We never remove previous observers
        node.removeAllChildren()
        
        for keyPathContainer in entity.nestedEntitiesKeyPaths {
            keyPathContainer.accept(node, entity, modifiedAt, storeVisitor)
        }
        
        withUnsafeMutablePointer(to: &entity) {
            let pointer = UnsafeMutableRawPointer($0)
            
            for (keyPath, childValue) in node.childrenValues() {
                pointer.assign(childValue, to: keyPath)
            }
        }
        
        // TODO: need to sync entity beforing applying it
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
