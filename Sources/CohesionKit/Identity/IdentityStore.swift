import Foundation
import Combine

public class IdentityMap {
    private(set) var storage: WeakStorage = WeakStorage()
    private lazy var storeVisitor = IdentityMapStoreVisitor(identityMap: self)
    
    public func store<T: Identifiable>(entity: T, modifiedAt: Stamp = Date().stamp) -> EntityObserver<T> {
        EntityObserver(node: store(entity: entity, modifiedAt: modifiedAt))
    }
    
    public func store<T: Aggregate>(entity: T, modifiedAt: Stamp = Date().stamp) -> EntityObserver<T> {
        EntityObserver(node: store(entity: entity, modifiedAt: modifiedAt))
    }
    
    public func store<C: Collection>(entities: C, modifiedAt: Stamp = Date().stamp) -> [EntityObserver<C.Element>]
    where C.Element: Identifiable {
        entities.map { EntityObserver(node: store(entity: $0, modifiedAt: modifiedAt)) }
    }
    
    public func store<C: Collection>(entities: C, modifiedAt: Stamp = Date().stamp) -> [EntityObserver<C.Element>]
    where C.Element: Aggregate {
        entities.map { EntityObserver(node: store(entity: $0, modifiedAt: modifiedAt)) }
    }
    
    func store<T: Identifiable>(entity: T, modifiedAt: Stamp) -> EntityNode<T> {
        guard let node = storage[entity] else {
            let node = EntityNode(entity, modifiedAt: modifiedAt)
            
            storage[entity] = node
            
            return node
        }
        
        node.updateEntity(entity, modifiedAt: modifiedAt)
        
        return node
    }
    
    func store<T: Aggregate>(entity: T, modifiedAt: Stamp) -> EntityNode<T> {
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

}
