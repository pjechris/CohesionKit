import Foundation
import Combine

public class IdentityMap {
    private(set) var storage: WeakStorage = WeakStorage()
    private(set) var refAliases: AliasStorage = [:]
    private lazy var storeVisitor = IdentityMapStoreVisitor(identityMap: self)
    private let logger: Logger?
    
    public init(logger: Logger? = nil) {
        self.logger = logger
    }
    
    public func store<T: Identifiable>(entity: T, named: AliasKey<T>? = nil, modifiedAt: Stamp = Date().stamp)
    -> EntityObserver<T> {
        let node = nodeStore(entity: entity, modifiedAt: modifiedAt)
        
        if let alias = named {
            refAliases.insert(node, key: alias)
            logger?.didRegisterAlias(alias)
        }
        
        return EntityObserver(node: node)
    }
    
    public func store<T: Aggregate>(entity: T, named: AliasKey<T>? = nil, modifiedAt: Stamp = Date().stamp)
    -> EntityObserver<T> {
        let node = nodeStore(entity: entity, modifiedAt: modifiedAt)
        
        if let alias = named {
            refAliases.insert(node, key: alias)
            logger?.didRegisterAlias(alias)
        }
        
        return EntityObserver(node: node)
    }
    
    public func store<C: Collection>(entities: C, named: AliasKey<C>? = nil, modifiedAt: Stamp = Date().stamp)
    -> [EntityObserver<C.Element>] where C.Element: Identifiable {
        let nodes = entities.map { nodeStore(entity: $0, modifiedAt: modifiedAt) }
        
        if let alias = named {
            refAliases.insert(nodes, key: alias)
            logger?.didRegisterAlias(alias)
        }
        
        return nodes.map { EntityObserver(node: $0) }
    }
    
    public func store<C: Collection>(entities: C, named: AliasKey<C>? = nil, modifiedAt: Stamp = Date().stamp)
    -> [EntityObserver<C.Element>] where C.Element: Aggregate {
        let nodes = entities.map { nodeStore(entity: $0, modifiedAt: modifiedAt) }
        
        if let alias = named {
            refAliases.insert(nodes, key: alias)
            logger?.didRegisterAlias(alias)
        }
        
        return nodes.map { EntityObserver(node: $0) }
    }
    
    public func find<T: Identifiable>(_ type: T.Type, id: T.ID) -> EntityObserver<T>? {
        if let node = storage[EntityNode<T>.self, id: id] {
            return EntityObserver(node: node)
        }
        
        return nil
    }
    
    /// Observe the entity registered under `named` alias
    public func find<T: Identifiable>(named: AliasKey<T>) -> AliasObserver<T> {
        AliasObserver(alias: refAliases[named])
    }
    
    /// Observe collection registered under `named` alias
    /// - Returns: an observer returning the alias value. Note that the value will be an Array
    public func find<C: Collection>(named: AliasKey<C>) -> AliasObserver<[C.Element]> {
        AliasObserver(alias: refAliases[named])
    }
    
    public func removeAlias<T>(named: AliasKey<T>) {
        refAliases.remove(for: named)
        logger?.didUnregisterAlias(named)
    }
    
    public func removeAlias<C: Collection>(named: AliasKey<C>) {
        refAliases.remove(for: named)
        logger?.didUnregisterAlias(named)
    }
    
    func nodeStore<T: Identifiable>(entity: T, modifiedAt: Stamp) -> EntityNode<T> {
        guard let node = storage[entity] else {
            let node = EntityNode(entity, modifiedAt: modifiedAt)
            
            storage[entity] = node
            
            return node
        }
        
        do {
            try node.updateEntity(entity, modifiedAt: modifiedAt)
            logger?.didStore(T.self, id: entity.id)
        }
        catch {
            logger?.didFailedToStore(T.self, id: entity.id, error: error)
        }
        
        return node
    }
    
    func nodeStore<T: Aggregate>(entity: T, modifiedAt: Stamp) -> EntityNode<T> {
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
        do {
            try node.updateEntity(entity, modifiedAt: modifiedAt)
            logger?.didStore(T.self, id: entity.id)
        }
        catch {
            logger?.didFailedToStore(T.self, id: entity.id, error: error)
        }
        
        node.applyChildrenChanges = true

        return node
    }

}
