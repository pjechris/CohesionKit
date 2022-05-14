import Foundation

/// Visitor storing entity nested keypaths into IdentityMap
struct IdentityMapStoreVisitor: NestedEntitiesVisitor {
    let identityMap: IdentityMap
    
    func visit<Root, T: Identifiable>(context: EntityContext<Root, T>, entity: T) {
        context
            .parent
            .observeChild(identityMap.nodeStore(entity: entity, modifiedAt: context.stamp), for: context.keyPath)
    }
    
    func visit<Root, T: Aggregate>(context: EntityContext<Root, T>, entity: T) {
        context
            .parent
            .observeChild(identityMap.nodeStore(entity: entity, modifiedAt: context.stamp), for: context.keyPath)
    }
    
    func visit<Root, T: Identifiable>(context: EntityContext<Root, T?>, entity: T?) {
        if let entity = entity {
            context
                .parent
                .observeChild(identityMap.nodeStore(entity: entity, modifiedAt: context.stamp), for: context.keyPath)
        }
    }
    
    func visit<Root, T: Aggregate>(context: EntityContext<Root, T?>, entity: T?) {
        if let entity = entity {
            context
                .parent
                .observeChild(identityMap.nodeStore(entity: entity, modifiedAt: context.stamp), for: context.keyPath)
        }
    }
    
    func visit<Root, C: BufferedCollection>(context: EntityContext<Root, C>, entities: C)
    where C.Element: Identifiable, C.Index == Int {
        
        for index in entities.indices {
            context.parent.observeChild(
                identityMap.nodeStore(entity: entities[index], modifiedAt: context.stamp),
                for: context.keyPath,
                index: index
            )
        }
    }
    
    func visit<Root, C: BufferedCollection>(context: EntityContext<Root, C>, entities: C)
    where C.Element: Aggregate, C.Index == Int {
        
        for index in entities.indices {
            context.parent.observeChild(
                identityMap.nodeStore(entity: entities[index], modifiedAt: context.stamp),
                for: context.keyPath,
                index: index
            )
        }
    }
}
