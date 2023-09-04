import XCTest
@testable import CohesionKit

class AliasObserverTests: XCTestCase {
    func test_observe_refValueChanged_onChangeIsCalled() {
        let ref = Observable(value: Optional.some(EntityNode(SingleNodeFixture(id: 1), modifiedAt: 0)))
        let registry = ObserverRegistry(queue: .main)
        let observer = AliasObserver(alias: ref, registry: registry)
        let newValue = SingleNodeFixture(id: 2)
        let expectation = XCTestExpectation()
        var droppedFirst = false

        let subscription = observer.observe {
            guard droppedFirst else {
                droppedFirst = true
                return
            }

            XCTAssertEqual($0, newValue)
            expectation.fulfill()
        }

        withExtendedLifetime(subscription) {
            let newNode = EntityNode(newValue, modifiedAt: 0)

            ref.value = newNode

            registry.enqueueChange(for: newNode)
            registry.postChanges()
        }

        wait(for: [expectation], timeout: 1)
    }

    func test_observe_registryPostEntityNotification_onChangeIsCalled() throws {
      let node = EntityNode(RootFixture(id: 1, primitive: "", singleNode: SingleNodeFixture(id: 0), listNodes: []), modifiedAt: 0)
      let registry = ObserverRegistry(queue: .main)
      let observer = AliasObserver(alias: Observable(value: node), registry: registry)
      let newValue = RootFixture(id: 1, primitive: "new value", singleNode: SingleNodeFixture(id: 1), listNodes: [])
      let expectation = XCTestExpectation()
      var droppedFirst = false

      let subscription = observer.observe {
        guard droppedFirst else {
            droppedFirst = true
            return
        }

        XCTAssertEqual($0, newValue)
        expectation.fulfill()
      }

      try withExtendedLifetime(subscription) {
        try node.updateEntity(newValue, modifiedAt: nil)

        registry.enqueueChange(for: node)
        registry.postChanges()

        wait(for: [expectation], timeout: 1)
      }
    }

    func test_observe_refValueChanged_entityIsUpdated_onChangeIsCalled() throws {
        let ref = Observable(value: Optional.some(EntityNode(SingleNodeFixture(id: 1), modifiedAt: 0)))
        let registry = ObserverRegistry(queue: .main)
        let observer = AliasObserver(alias: ref, registry: registry)
        let newNode = EntityNode(SingleNodeFixture(id: 2), modifiedAt: 0)
        let newValue = SingleNodeFixture(id: 3)
        var lastReceivedValue: SingleNodeFixture?
        let expectation = XCTestExpectation()

        expectation.expectedFulfillmentCount = 3

        let subscription = observer.observe {
            lastReceivedValue = $0
            expectation.fulfill()
        }

        try withExtendedLifetime(subscription) {
            ref.value = newNode

            try newNode.updateEntity(newValue, modifiedAt: nil)

            registry.enqueueChange(for: newNode)
            registry.postChanges()
        }

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(lastReceivedValue, newValue)
    }

    func test_observe_subscriptionIsCancelled_unsubscribeToUpdates() throws {
        let initialValue = SingleNodeFixture(id: 1)
        let registry = ObserverRegistry(queue: .main)
        let node = EntityNode(initialValue, modifiedAt: 0)
        let ref = Observable(value: Optional.some(node))
        let observer = AliasObserver(alias: ref, registry: registry)
        let newValue = SingleNodeFixture(id: 3)
        var lastReceivedValue: SingleNodeFixture?
        var firstDropped = false

        _ = observer.observe {
            guard firstDropped else {
                firstDropped = true
                return
            }

            lastReceivedValue = $0
        }

        try node.updateEntity(newValue, modifiedAt: 1)

        registry.enqueueChange(for: node)
        registry.postChanges()

        XCTAssertNil(lastReceivedValue)
    }

    func test_observeArray_registryPostNotificationForElement_onChangeIsCalled() throws {
        let expectation = XCTestExpectation()
        let nodes = [
            EntityNode(SingleNodeFixture(id: 1), modifiedAt: 0),
            EntityNode(SingleNodeFixture(id: 2), modifiedAt: 0)
        ]
        let ref = Observable(value: Optional.some(nodes))
        let registry = ObserverRegistry(queue: .main)
        let observer = AliasObserver(alias: ref, registry: registry)
        let update = SingleNodeFixture(id: 1, primitive: "Update")
        var firstDropped = false
        var subscription: Subscription?

        subscription = observer.observe { value in
            guard firstDropped else {
                firstDropped = true
                return
            }

            withExtendedLifetime(subscription) {
                expectation.fulfill()
                XCTAssertEqual(value?.first, update)
            }
        }

        try nodes[0].updateEntity(update, modifiedAt: nil)

        registry.enqueueChange(for: nodes[0])
        registry.postChanges()

        wait(for: [expectation], timeout: 1)
    }
}
