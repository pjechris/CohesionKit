import XCTest
@testable import CohesionKit

class AliasObserverTests: XCTestCase {
    func test_observe_refValueChanged_returnRefValue() {
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
}
