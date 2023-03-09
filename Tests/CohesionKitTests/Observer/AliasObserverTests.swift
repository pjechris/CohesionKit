import XCTest
@testable import CohesionKit

class AliasObserverTests: XCTestCase {
    func test_observe_refValueChanged_onChangeIsCalled() {
        let ref = Ref(value: Optional.some(EntityNode(SingleNodeFixture(id: 1), modifiedAt: 0)))
        let observer = AliasObserver(alias: ref, queue: .main)
        let newValue = SingleNodeFixture(id: 2)
        var lastReceivedValue: SingleNodeFixture?
        let expectation = XCTestExpectation()
        
        let subscription = observer.observe {
            lastReceivedValue = $0
            expectation.fulfill()
        }
        
        withExtendedLifetime(subscription) {
            ref.value = EntityNode(newValue, modifiedAt: 0)
        }
        
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(lastReceivedValue, newValue)
    }
    
    func test_observe_refValueChanged_subscribeToValueUpdates() throws {
        let ref = Ref(value: Optional.some(EntityNode(SingleNodeFixture(id: 1), modifiedAt: 0)))
        let observer = AliasObserver(alias: ref, queue: .main)
        let newNode = EntityNode(SingleNodeFixture(id: 2), modifiedAt: 0)
        let newValue = SingleNodeFixture(id: 3)
        var lastReceivedValue: SingleNodeFixture?
        let expectation = XCTestExpectation()
        
        let subscription = observer.observe {
            lastReceivedValue = $0
            expectation.fulfill()
        }
        
        try withExtendedLifetime(subscription) {
            ref.value = newNode
            try newNode.updateEntity(newValue, modifiedAt: 1)
        }
        
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(lastReceivedValue, newValue)
    }
    
    func test_observe_subscriptionIsCancelled_unsubscribeToUpdates() throws {
        let initialValue = SingleNodeFixture(id: 1)
        let node = EntityNode(initialValue, modifiedAt: 0)
        let ref = Ref(value: Optional.some(node))
        let observer = AliasObserver(alias: ref, queue: .main)
        let newValue = SingleNodeFixture(id: 3)
        var lastReceivedValue: SingleNodeFixture?

        _ = observer.observe {
            lastReceivedValue = $0
        }

        try node.updateEntity(newValue, modifiedAt: 1)

        XCTAssertNil(lastReceivedValue)
    }

    func test_observeArray_oneElementChanged_onChangeIsCalled() throws {
        let expectation = XCTestExpectation()
        let entities = [
            EntityNode(SingleNodeFixture(id: 1), modifiedAt: 0),
            EntityNode(SingleNodeFixture(id: 2), modifiedAt: 0)
        ]
        let ref = Ref(value: Optional.some(entities))
        let observer = AliasObserver(alias: ref, queue: .main)
        let update = SingleNodeFixture(id: 1, primitive: "Update")
        var lastObservedValue: [SingleNodeFixture]?

        let subscription = observer.observe {
            lastObservedValue = $0
            expectation.fulfill()
        }

        try withExtendedLifetime(subscription) {
            // try ref.value?[0].updateEntity(SingleNodeFixture(id: 1, primitive: "Update"), modifiedAt: 1)
            try entities[0].updateEntity(SingleNodeFixture(id: 1, primitive: "Update"), modifiedAt: 1)

            wait(for: [expectation], timeout: 1)
            XCTAssertEqual(lastObservedValue?.first, update)
        }
    }
}
