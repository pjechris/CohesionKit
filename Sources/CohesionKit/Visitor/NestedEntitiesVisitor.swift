import Foundation

/// A protocol allowing visiting entity nested keypath entities
protocol NestedEntitiesVisitor {
    func visit<Root, T: Identifiable>(context: EntityContext<Root, T>, entity: T)
    func visit<Root, T: Aggregate>(context: EntityContext<Root, T>, entity: T)

    func visit<Root, T: Identifiable>(context: EntityContext<Root, T?>, entity: T?)
    func visit<Root, T: Aggregate>(context: EntityContext<Root, T?>, entity: T?)

    func visit<Root, C: MutableCollection>(context: EntityContext<Root, C>, entities: C)
    where C.Element: Identifiable, C.Index: Hashable

    func visit<Root, C: MutableCollection>(context: EntityContext<Root, C>, entities: C)
    where C.Element: Aggregate, C.Index: Hashable
}
