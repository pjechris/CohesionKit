@testable import CohesionKit

/// An ObserverRegistry stub: all methods have default behaviour. Some can be mocked and some can be tracked
class ObserverRegistryStub: ObserverRegistry {
    var enqueueChangeCalled: (AnyHashable) -> Void = { _ in }
    /// Enqueued changes. Not typed. A same change could be enqueue multiple times (for testing purposes!)
    private var pendingChangesStub: [Any] = []

    override func enqueueChange<T>(for node: EntityNode<T>) {
        pendingChangesStub.append(node)
        enqueueChangeCalled(AnyHashable(node))
        super.enqueueChange(for: node)
    }

    func hasPendingChange<T: Equatable>(for entity: T) -> Bool {
        pendingChangesStub.contains { ($0 as? EntityNode<T>)?.ref.value == entity }
    }

    func hasPendingChange<T>(for _: T.Type) -> Bool {
        pendingChangesStub.contains { ($0 as? EntityNode<T>) != nil }
    }

    /// number of times change has been inserted for this entity
    func pendingChangeCount<T: Equatable>(for entity: T) -> Int {
        pendingChangesStub.filter { ($0 as? EntityNode<T>)?.ref.value == entity }.count
    }

    func clearPendingChangesStub() {
        pendingChangesStub.removeAll()
    }
}
