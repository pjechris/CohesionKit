@testable import CohesionKit

/// An ObserverRegistry stub: all methods have default behaviour. Some can be mocked and some can be tracked
class ObserverRegistryStub: ObserverRegistry {
    var enqueueChangeCalled: (AnyHashable) -> Void = { _ in }

    override func enqueueChange<T>(for node: EntityNode<T>) {
        enqueueChangeCalled(AnyHashable(node))
        super.enqueueChange(for: node)
    }

    func hasPendingChange<T: Equatable>(for entity: T) -> Bool {
        pendingChanges.values.contains { ($0.unwrap() as? EntityNode<T>)?.ref.value == entity }
    }
}