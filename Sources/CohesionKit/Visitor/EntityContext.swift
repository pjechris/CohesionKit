import Foundation

/// Information related to an entity while storing it into the `IdentityMap`
struct EntityContext<Root, Value> {
    let parent: EntityNode<Root>
    let keyPath: KeyPath<Root, Value>
    let stamp: Stamp
}
