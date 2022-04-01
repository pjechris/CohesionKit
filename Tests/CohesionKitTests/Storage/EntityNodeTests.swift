import XCTest
@testable import CohesionKit

class EntityNodeTests: XCTestCase {
    let startEntity = RootFixture(
        id: 1,
        primitive: "hello",
        singleNode: SingleNodeFixture(id: 1),
        optional: nil,
        listNodes: []
    )
    let startTimestamp: Stamp = 0
    
    let newEntity = RootFixture(
        id: 1,
        primitive: "hello world",
        singleNode: SingleNodeFixture(id: 1),
        optional: nil,
        listNodes: []
    )
    
    var node: EntityNode<RootFixture>!
    
    override func setUp() {
        node = EntityNode(startEntity, modifiedAt: startTimestamp)
    }
    
    func test_updateEntity_stampIsEqual_entityIsUpdated() {
        node.updateEntity(newEntity, modifiedAt: startTimestamp)
        
        XCTAssertEqual(node.value as? RootFixture, newEntity)
    }
    
    func test_updateEntity_stampIsSup_entityIsUpdated() {
        node.updateEntity(newEntity, modifiedAt: startTimestamp + 1)
        
        XCTAssertEqual(node.value as? RootFixture, newEntity)
    }
    
    func test_updateEntity_stampIsInf_entityIsNotUpdated() {
        node.updateEntity(newEntity, modifiedAt: startTimestamp - 1)
        
        XCTAssertEqual(node.value as? RootFixture, startEntity)
    }
    
    func test_observeChild_childChange_entityIsUpdated() {
        let childNode = EntityNode(startEntity.singleNode, modifiedAt: 0)
        let newChild = SingleNodeFixture(id: 1, primitive: "updated")
        
        node.observeChild(childNode, for: \.singleNode)
        
        childNode.updateEntity(newChild, modifiedAt: 1)
        
        XCTAssertEqual((node.value as? RootFixture)?.singleNode, newChild)
    }
    
    func test_observeChild_childChange_entityObserversAreCalled() {
        let childNode = EntityNode(startEntity.singleNode, modifiedAt: startTimestamp)
        let newChild = SingleNodeFixture(id: 1, primitive: "updated")
        let entityRef = Ref(value: startEntity)
        var observerCalled = false
        
        let subscription = entityRef.addObserver { _ in
            observerCalled = true
        }
        
        node = EntityNode(ref: entityRef, modifiedAt: startTimestamp)
        node.observeChild(childNode, for: \.singleNode)
        
        childNode.updateEntity(newChild, modifiedAt: startTimestamp + 1)
        
        subscription.unsubscribe()
        
        XCTAssertTrue(observerCalled)
    }
    
    func test_observeChildIndex_eachChildIsAdded() {
        let child1 = EntityNode(ListNodeFixture(id: 1), modifiedAt: startTimestamp)
        let child2 = EntityNode(ListNodeFixture(id: 2), modifiedAt: startTimestamp)
        let node = EntityNode(startEntity, modifiedAt: startTimestamp)
        
        XCTAssertEqual(node.children.count, 0)
        
        node.observeChild(child1, for: \.listNodes, index: 0)
        node.observeChild(child2, for: \.listNodes, index: 1)
        
        XCTAssertEqual(node.children.count, 2)
    }
}
