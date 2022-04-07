import Foundation
import Combine

public class IdentityMap {
    private(set) var storage: WeakStorage = WeakStorage()
    private(set) var refAliases: AliasStorage = [:]
    private lazy var storeVisitor = IdentityMapStoreVisitor(identityMap: self)
    
    public func store<T: Identifiable>(entity: T, named: AliasKey<T>? = nil, modifiedAt: Stamp = Date().stamp)
    -> EntityObserver<T> {
        let node = store(entity: entity, modifiedAt: modifiedAt)
        
        refAliases.insert(node, key: named)
        
        return EntityObserver(node: node)
    }
    
    public func store<T: Aggregate>(entity: T, named: AliasKey<T>? = nil, modifiedAt: Stamp = Date().stamp)
    -> EntityObserver<T> {
        let node = store(entity: entity, modifiedAt: modifiedAt)
        
        refAliases.insert(node, key: named)
        
        return EntityObserver(node: node)
    }
    
    public func store<C: Collection>(entities: C, named: AliasKey<C>? = nil, modifiedAt: Stamp = Date().stamp)
    -> [EntityObserver<C.Element>] where C.Element: Identifiable {
        let nodes = entities.map { store(entity: $0, modifiedAt: modifiedAt) }
        
        refAliases.insert(nodes, key: named)
        
        return nodes.map { EntityObserver(node: $0) }
    }
    
    public func store<C: Collection>(entities: C, named: AliasKey<C>? = nil, modifiedAt: Stamp = Date().stamp)
    -> [EntityObserver<C.Element>] where C.Element: Aggregate {
        let nodes = entities.map { store(entity: $0, modifiedAt: modifiedAt) }
        
        refAliases.insert(nodes, key: named)
        
        return nodes.map { EntityObserver(node: $0) }
    }
    
    public func find<T: Identifiable>(_ type: T.Type, id: T.ID) -> EntityObserver<T>? {
        if let node = storage[EntityNode<T>.self, id: id] {
            return EntityObserver(node: node)
        }
        
        return nil
    }
    
    public func find<T: Identifiable>(named: AliasKey<T>) -> AliasObserver<T> {
        AliasObserver(alias: refAliases[named])
    }
    
    public func find<C: Collection>(named: AliasKey<C>) -> AliasObserver<C> {
        AliasObserver(alias: refAliases[named])
    }
    
    public func remove<T>(name: AliasKey<T>) {
        refAliases.remove(for: name)
    }
    
    public func remove<C: Collection>(name: AliasKey<C>) {
        refAliases.remove(for: name)
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
