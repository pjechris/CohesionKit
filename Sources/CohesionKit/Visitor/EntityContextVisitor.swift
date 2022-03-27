import Foundation

struct IdentityMapStoreVisitor: IdentityVisitor {
    let identityMap: IdentityMap
    
    func visit<Root, T: Identifiable>(context: EntityContext<Root, T>, entity: T) {
        context.parent.observeChild(identityMap.store(entity: entity, modifiedAt: context.stamp), for: context.keyPath)
    }
    
    func visit<Root, T: Aggregate>(context: EntityContext<Root, T>, entity: T) {
        context.parent.observeChild(identityMap.store(entity: entity, modifiedAt: context.stamp), for: context.keyPath)
    }
    
    func visit<Root, C: Collection>(context: EntityContext<Root, C>, entities: C)
    where C.Element: Identifiable, C.Index: Hashable {
        
        for index in entities.indices {
            context.parent.observeChild(
                identityMap.store(entity: entities[index], modifiedAt: context.stamp),
                for: context.keyPath.appending(path: \C[index])
            )
        }
    }
    
    func visit<Root, C: Collection>(context: EntityContext<Root, C>, entities: C)
    where C.Element: Aggregate, C.Index: Hashable {
        
        for index in entities.indices {
            context.parent.observeChild(
                identityMap.store(entity: entities[index], modifiedAt: context.stamp),
                for: context.keyPath.appending(path: \C[index])
            )
        }
    }
}
