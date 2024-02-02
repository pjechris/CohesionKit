import XCTest
@testable import CohesionKit

class EntityObserverTests: XCTestCase {
    func test_async_valueUpdatedBeforeAwaiting_returnsLatestValue() async throws {
        let initialValue = SingleNodeFixture(id: 1)
        let newValue = SingleNodeFixture(id: 1, primitive: "new")
        let registry = ObserverRegistryStub()
        let node = EntityNode(initialValue, modifiedAt: nil)
        let observer = EntityObserver(node: node, registry: registry)
        var receivedValues: [SingleNodeFixture] = []

        try node.updateEntity(newValue, modifiedAt: nil)
        registry.enqueueChange(for: node)

        for await value in observer.async.prefix(1) {
            receivedValues.append(value)
        }

        XCTAssertEqual(receivedValues, [newValue])
    }

    func test_async_valueUpdatedAfterAwaiting_returnsLatestValue() async throws {
        let initialValue = SingleNodeFixture(id: 1)
        let newValue = SingleNodeFixture(id: 1, primitive: "new")
        let registry = ObserverRegistryStub()
        let node = EntityNode(initialValue, modifiedAt: nil)
        let observer = EntityObserver(node: node, registry: registry)

        let task = Task {
            var receivedValues: [SingleNodeFixture] = []

            for await value in observer.async.prefix(1) {
                receivedValues.append(value)
            }

            return receivedValues
        }

        try node.updateEntity(newValue, modifiedAt: nil)
        registry.enqueueChange(for: node)

        await Task.yield()

        let result = await task.value
        XCTAssertEqual(result, [newValue])
    }
}