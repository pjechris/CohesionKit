import Foundation

struct EntityContext<Root, Value> {
    let parent: EntityNode<Root>
    let keyPath: KeyPath<Root, Value>
}
