import XCTest
@testable import CohesionKit

class ObserverRegistryTests: XCTestCase {
    func test_postNotification_nodeIsModifiedAfterEnqueue_observerIsCalledWithLatestValue() {
        let registry = ObserverRegistry(queue: .main)
        let node = EntityNode(SingleNodeFixture(id: 0), modifiedAt: nil)
        let newEntity = SingleNodeFixture(id: 0, primitive: "new entity version")
        let expectation = XCTestExpectation()

        let subscription = registry.addObserver(node: node) {
            expectation.fulfill()
            XCTAssertEqual($0, newEntity)
        }

        withExtendedLifetime(subscription) {
            registry.enqueueNotification(for: node)

            // simulates node changing twice
            try? node.updateEntity(newEntity, modifiedAt: nil)
            registry.enqueueNotification(for: node)

            registry.postNotifications()
        }

        wait(for: [expectation], timeout: 0.5)
    }

    func test_postNotification_nodeEnqueuedMultipleTimes_postOnlyOnce() {
        let registry = ObserverRegistry(queue: .main)
        let node = EntityNode(SingleNodeFixture(id: 0), modifiedAt: nil)
        let expectation = XCTestExpectation()

        expectation.assertForOverFulfill = true
        expectation.expectedFulfillmentCount = 1

        let subscription = registry.addObserver(node: node) { _ in
            expectation.fulfill()
        }

        withExtendedLifetime(subscription) {
            registry.enqueueNotification(for: node)
            registry.enqueueNotification(for: node)
            registry.enqueueNotification(for: node)

            registry.postNotifications()
        }

        wait(for: [expectation], timeout: 0.5)
    }
}