import Foundation

protocol IdentityVisitor {
    func visit<Root, T: Identifiable>(context: EntityContext<Root, T>, entity: T)
    func visit<Root, T: Aggregate>(context: EntityContext<Root, T>, entity: T)
    
    func visit<Root, C: Collection>(context: EntityContext<Root, C>, entities: C)
    where C.Element: Identifiable, C.Index: Hashable
    
    func visit<Root, C: Collection>(context: EntityContext<Root, C>, entities: C)
    where C.Element: Aggregate, C.Index: Hashable
}
