@testable import CohesionKit

/// An ObserverRegistry stub: all methods have default behaviour. Some can be mocked and some can be tracked
class ObserverRegistryStub: ObserverRegistry {
    var enqueueChangeCalled: (AnyHashable) -> Void = { _ in }
    private var pendingChangesStub: [Any] = []


    override func enqueueChange<T>(for node: EntityNode<T>) {
        pendingChangesStub.append(node)
        enqueueChangeCalled(AnyHashable(node))
        super.enqueueChange(for: node)
    }

    func hasPendingChange<T: Equatable>(for entity: T) -> Bool {
        pendingChangesStub.contains { ($0 as? EntityNode<T>)?.ref.value == entity }
    }
}