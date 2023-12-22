import Foundation

/// Visitor storing entity nested keypaths into EntityStore
struct EntityStoreStoreVisitor: NestedEntitiesVisitor {
    let entityStore: EntityStore

    func visit<Root, T: Identifiable>(context: EntityContext<Root, T>, entity: T) {
        let storedChild = entityStore.nodeStore(entity: entity, modifiedAt: context.stamp)

        context
            .parent
            .observeChild(storedChild, for: context.keyPath)
    }

    func visit<Root, T: Aggregate>(context: EntityContext<Root, T>, entity: T) {
        let storedChild = entityStore.nodeStore(entity: entity, modifiedAt: context.stamp)

        context
            .parent
            .observeChild(storedChild, for: context.keyPath)
    }

    func visit<Root, T: Identifiable>(context: EntityContext<Root, T?>, entity: T?) {
        if let entity = entity {
            context
                .parent
                .observeChild(entityStore.nodeStore(entity: entity, modifiedAt: context.stamp), for: context.keyPath)
        }
    }

    func visit<Root, T: Aggregate>(context: EntityContext<Root, T?>, entity: T?) {
        if let entity = entity {
            context
                .parent
                .observeChild(entityStore.nodeStore(entity: entity, modifiedAt: context.stamp), for: context.keyPath)
        }
    }

    func visit<Root, C: MutableCollection>(context: EntityContext<Root, C>, entities: C)
    where C.Element: Identifiable, C.Index: Hashable {
        for index in entities.indices {
            context.parent.observeChild(
                entityStore.nodeStore(entity: entities[index], modifiedAt: context.stamp),
                for: context.keyPath.appending(path: \.[index])
            )
        }
    }

    func visit<Root, C: MutableCollection>(context: EntityContext<Root, C>, entities: C)
    where C.Element: Aggregate, C.Index: Hashable {

        for index in entities.indices {
            context.parent.observeChild(
                entityStore.nodeStore(entity: entities[index], modifiedAt: context.stamp),
                for: context.keyPath.appending(path: \.[index])
            )
        }
    }
}
