import Foundation

/// Information related to an entity while storing it into the `EntityStore`
struct EntityContext<Root, Value> {
    let parent: EntityNode<Root>
    let keyPath: WritableKeyPath<Root, Value>
    let stamp: Stamp?
}
