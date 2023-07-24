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

    func test_updateEntity_stampIsEqual_entityIsNotUpdated() throws {
        XCTAssertThrowsError(
            try node.updateEntity(newEntity, modifiedAt: startTimestamp)
        )

        XCTAssertEqual(node.value as? RootFixture, startEntity)
    }

    func test_updateEntity_stampIsSup_entityIsUpdated() throws {
        try node.updateEntity(newEntity, modifiedAt: startTimestamp + 1)

        XCTAssertEqual(node.value as? RootFixture, newEntity)
    }

    func test_updateEntity_stampIsInf_entityIsNotUpdated() throws {
        XCTAssertThrowsError(
            try node.updateEntity(newEntity, modifiedAt: startTimestamp - 1)
        )

        XCTAssertEqual(node.value as? RootFixture, startEntity)
    }

    func test_updateEntity_stampIsNil_entityIsUpdated() throws {
        try node.updateEntity(newEntity, modifiedAt: nil)

        XCTAssertEqual(node.value as? RootFixture, newEntity)
    }

    func test_updateEntity_stampIsNil_stampIsNotUpdated() throws {
        let badEntity = RootFixture(id: 1, primitive: "wrong update", singleNode: .init(id: 1), listNodes: [])

        try node.updateEntity(newEntity, modifiedAt: nil)

        XCTAssertThrowsError(try node.updateEntity(badEntity, modifiedAt: startTimestamp - 1)) { error in
            switch error {
                case StampError.tooOld(let current, _):
                    XCTAssertEqual(current, startTimestamp)
                default:
                    XCTFail("Wrong error thrown")
            }
        }
    }

    func test_observeChild_childChange_entityIsUpdated() throws {
        let childNode = EntityNode(startEntity.singleNode, modifiedAt: nil)
        let newChild = SingleNodeFixture(id: 1, primitive: "updated")

        node.observeChild(childNode, for: \.singleNode)

        try childNode.updateEntity(newChild, modifiedAt: nil)

        XCTAssertEqual((node.value as? RootFixture)?.singleNode, newChild)
    }

    func test_observeChild_childChange_entityObserversAreCalled() throws {
        let childNode = EntityNode(startEntity.singleNode, modifiedAt: startTimestamp)
        let newChild = SingleNodeFixture(id: 1, primitive: "updated")
        let entityRef = Observable(value: startEntity)
        var observerCalled = false

        let subscription = entityRef.addObserver { _ in
            observerCalled = true
        }

        node = EntityNode(ref: entityRef, modifiedAt: startTimestamp)
        node.observeChild(childNode, for: \.singleNode)

        try childNode.updateEntity(newChild, modifiedAt: nil)

        subscription.unsubscribe()

        XCTAssertTrue(observerCalled)
    }

    func test_observeChild_childIsCollection_eachChildIsAdded() {
        let child1 = EntityNode(ListNodeFixture(id: 1), modifiedAt: startTimestamp)
        let child2 = EntityNode(ListNodeFixture(id: 2), modifiedAt: startTimestamp)
        let node = EntityNode(startEntity, modifiedAt: startTimestamp)

        XCTAssertEqual(node.children.count, 0)

        node.observeChild(child1, for: \.listNodes[0])
        node.observeChild(child2, for: \.listNodes[1])

        XCTAssertEqual(node.children.count, 2)
    }
}
