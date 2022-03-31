import XCTest
@testable import CohesionKit

class IdentityMapStoreVisitorTests: XCTestCase {
    func test_visit_identifiableEntities_callObserveChildWithASubscriptKeyPath() {
        let collection: [ListNodeFixture] = [.init(id: 2)]
        let entity = RootFixture(id: 1, primitive: "", singleNode: .init(id: 1), optional: nil, listNodes: collection)
        let parent = EntityNodeStub(entity, modifiedAt: 0)
        let context = EntityContext(parent: parent, keyPath: \RootFixture.listNodes, stamp: 0)
        
        parent.observeChildCalled = { _, keyPath in
            XCTAssertEqual(keyPath, \RootFixture.listNodes[0])
        }
        
        IdentityMapStoreVisitor(identityMap: IdentityMap())
            .visit(context: context, entities: collection)
    }
}

private class EntityNodeStub<T>: EntityNode<T> {
    var observeChildCalled: (AnyEntityNode, PartialKeyPath<T>) -> () = { _, _ in }
    
    override func observeChild<C>(_ childNode: EntityNode<C>, for keyPath: KeyPath<T, C>) {
        observeChildCalled(childNode, keyPath)
    }
}
