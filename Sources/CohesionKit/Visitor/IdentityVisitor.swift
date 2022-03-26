import Foundation

protocol IdentityVisitor {
    func visit<Root, T: Identifiable>(context: EntityContext<Root, T>, entity: T)
    func visit<Root, T: Aggregate>(context: EntityContext<Root, T>, entity: T)
}
