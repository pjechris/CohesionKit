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
            registry.enqueueChange(for: node)

            // simulates node changing twice
            try? node.updateEntity(newEntity, modifiedAt: nil)
            registry.enqueueChange(for: node)

            registry.postChanges()

            wait(for: [expectation], timeout: 0.1)
        }
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
            registry.enqueueChange(for: node)
            registry.enqueueChange(for: node)
            registry.enqueueChange(for: node)

            registry.postChanges()
        }

        wait(for: [expectation], timeout: 0.1)
    }

    func test_postNotification_observerIsUnsubscribed_observerIsNotCalled() {
        let registry = ObserverRegistry(queue: .main)
        let node = EntityNode(SingleNodeFixture(id: 0), modifiedAt: nil)
        let expectation = XCTestExpectation()

        expectation.isInverted = true

        _ = registry.addObserver(node: node) { _ in
            XCTFail()
            expectation.fulfill()
        }

        registry.enqueueChange(for: node)
        registry.postChanges()

        wait(for: [expectation], timeout: 0.1)
    }

    func test_postNotification_isEnqueuedAfter_observerIsNotCalled() {
        let registry = ObserverRegistry(queue: .main)
        let node = EntityNode(SingleNodeFixture(id: 0), modifiedAt: nil)
        let expectation = XCTestExpectation()
        let subscription = registry.addObserver(node: node) { _ in
            expectation.fulfill()
        }

        expectation.isInverted = true

        registry.postChanges()
        registry.enqueueChange(for: node)

        withExtendedLifetime(subscription) {
            wait(for: [expectation], timeout: 0.1)
        }
    }

    func test_postNotification_calledMultipleTimes_observerIsCalledOnlyOnce() {
        let registry = ObserverRegistry(queue: .main)
        let node = EntityNode(SingleNodeFixture(id: 0), modifiedAt: nil)
        let expectation = XCTestExpectation()

        expectation.assertForOverFulfill = true
        expectation.expectedFulfillmentCount = 1

        let subscription = registry.addObserver(node: node) { _ in
            expectation.fulfill()
        }

        registry.enqueueChange(for: node)
        registry.postChanges()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            registry.postChanges()
        }

        withExtendedLifetime(subscription) {
            wait(for: [expectation], timeout: 0.2)
        }
    }
}