import XCTest
@testable import CohesionKit

class AliasObserverTests: XCTestCase {
    func test_observe_refChanged_returnRefValue() {
        let ref = Ref(value: Optional.some(EntityNode(SingleNodeFixture(id: 1), modifiedAt: 0)))
        let observer = AliasObserver(alias: ref)
        let newValue = SingleNodeFixture(id: 2)
        var lastReceivedValue: SingleNodeFixture?
        
        let subscription = observer.observe {
            lastReceivedValue = $0
        }
        
        withExtendedLifetime(subscription) {
            ref.value = EntityNode(newValue, modifiedAt: 0)
        }
        
        XCTAssertEqual(lastReceivedValue, newValue)
    }
    
    func test_observe_refChanged_subscribeToRefUpdates() {
        let ref = Ref(value: Optional.some(EntityNode(SingleNodeFixture(id: 1), modifiedAt: 0)))
        let observer = AliasObserver(alias: ref)
        let newNode = EntityNode(SingleNodeFixture(id: 2), modifiedAt: 0)
        let newValue = SingleNodeFixture(id: 3)
        var lastReceivedValue: SingleNodeFixture?
        
        let subscription = observer.observe {
            lastReceivedValue = $0
        }
        
        withExtendedLifetime(subscription) {
            ref.value = newNode
            newNode.updateEntity(newValue, modifiedAt: 1)
        }
        
        XCTAssertEqual(lastReceivedValue, newValue)
    }
    
    func test_observe_subscriptionIsCancelled_unsubscribeToUpdates() {
        let initialValue = SingleNodeFixture(id: 1)
        let node = EntityNode(initialValue, modifiedAt: 0)
        let ref = Ref(value: Optional.some(node))
        let observer = AliasObserver(alias: ref)
        let newValue = SingleNodeFixture(id: 3)
        var lastReceivedValue: SingleNodeFixture?
        
        _ = observer.observe {
            lastReceivedValue = $0
        }
        
        node.updateEntity(newValue, modifiedAt: 1)
        
        XCTAssertNil(lastReceivedValue)
    }
}
