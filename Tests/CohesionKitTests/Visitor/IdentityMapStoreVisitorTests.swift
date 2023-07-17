import XCTest
@testable import CohesionKit

class IdentityMapStoreVisitorTests: XCTestCase {
    let parent = RootFixture(id: 1, primitive: "", singleNode: .init(id: 1), optional: nil, listNodes: [.init(id: 2)])
    private var parentNode: EntityNodeStub<RootFixture>!

    override func setUp() {
        parentNode = EntityNodeStub(parent, modifiedAt: 0)
    }

    func test_visit_identifiableEntities_observeChildByIndex() {
        let collection = [ListNodeFixture(id: 1)]
        let context = EntityContext(parent: parentNode, keyPath: \RootFixture.listNodes, stamp: 0)
        let expectation = XCTestExpectation()

        parentNode.observeChildKeyPathCalled = { _, keyPath in
            expectation.fulfill()
            // can't compare keyPath directly: seems it does not produce exactly the same keypath when using direct variable 🧐
            XCTAssertTrue(type(of: keyPath).valueType == ListNodeFixture.self)
        }

        IdentityMapStoreVisitor(identityMap: IdentityMap())
            .visit(context: context, entities: collection)

        wait(for: [expectation], timeout: 0)
    }

    func test_visit_optionalIdentifiableEntity_observeChildWithAnOptionalKeyPath() {
        let expectation = XCTestExpectation()
        let entity = OptionalNodeFixture(id: 1)
        let context = EntityContext(parent: parentNode, keyPath: \RootFixture.optional, stamp: 0)

        parentNode.observeChildKeyPathOptionalCalled = { _, _ in
            expectation.fulfill()
        }

        IdentityMapStoreVisitor(identityMap: IdentityMap())
            .visit(context: context, entity: .some(entity))

        wait(for: [expectation], timeout: 0)
    }

    func test_visit_optionalIdentifiableEntity_entityIsNil_doNoObservation() {
        let expectation = XCTestExpectation()
        let context = EntityContext(parent: parentNode, keyPath: \RootFixture.optional, stamp: 0)

        expectation.isInverted = true

        parentNode.observeChildKeyPathOptionalCalled = { _, _ in
            expectation.fulfill()
        }

        IdentityMapStoreVisitor(identityMap: IdentityMap())
            .visit(context: context, entity: nil)

        wait(for: [expectation], timeout: 0)
    }
}

private class EntityNodeStub<T>: EntityNode<T> {
    var observeChildKeyPathCalled: (AnyEntityNode, PartialKeyPath<T>) -> Void = { _, _ in }
    var observeChildKeyPathOptionalCalled: (AnyEntityNode, PartialKeyPath<T>) -> Void = { _, _ in }

    override func observeChild<C>(_ childNode: EntityNode<C>, for keyPath: WritableKeyPath<T, C>) {
        observeChildKeyPathCalled(childNode, keyPath)
    }

    override func observeChild<C>(_ childNode: EntityNode<C>, for keyPath: WritableKeyPath<T, C?>) {
        observeChildKeyPathOptionalCalled(childNode, keyPath)
    }
}
