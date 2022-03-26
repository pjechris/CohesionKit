import Foundation

struct EntityContextVisitor: IdentityVisitor {
    let identityMap: IdentityMap
    
    func visit<Root, T: Identifiable>(context: EntityContext<Root, T>, entity: T) {
        context.parent.observeChild(identityMap.store(entity: entity), for: context.keyPath)
    }
    
    func visit<Root, T: Aggregate>(context: EntityContext<Root, T>, entity: T) {
        context.parent.observeChild(identityMap.store(entity: entity), for: context.keyPath)
    }
}
