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

        XCTAssertEqual(node.value, startEntity)
    }

    func test_updateEntity_stampIsSup_entityIsUpdated() throws {
        try node.updateEntity(newEntity, modifiedAt: startTimestamp + 1)

        XCTAssertEqual(node.value, newEntity)
    }

    func test_updateEntity_stampIsInf_entityIsNotUpdated() throws {
        XCTAssertThrowsError(
            try node.updateEntity(newEntity, modifiedAt: startTimestamp - 1)
        )

        XCTAssertEqual(node.value, startEntity)
    }

    func test_updateEntity_stampIsNil_entityIsUpdated() throws {
        try node.updateEntity(newEntity, modifiedAt: nil)

        XCTAssertEqual(node.value, newEntity)
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

    func test_observeChild_nodeIsAddedAsParentMetadata() {
        let childNode = EntityNode(startEntity.singleNode, modifiedAt: nil)

        node.observeChild(childNode, for: \.singleNode)

        XCTAssertTrue(childNode.metadata.parentsRefs.contains(node.storageKey))
    }

    func test_observeChild_childrenMetadataIsUpdated() {
        let childNode = EntityNode(startEntity.singleNode, modifiedAt: nil)

        node.observeChild(childNode, for: \.singleNode)

        XCTAssertTrue(node.metadata.childrenRefs.keys.contains(childNode.storageKey))
    }

    func test_updateEntityRelationship_childIsUpdated() throws {
        let childNode = EntityNode(startEntity.singleNode, modifiedAt: startTimestamp)
        let newChild = SingleNodeFixture(id: 1, primitive: "updated")

        node.observeChild(childNode, for: \.singleNode)

        try childNode.updateEntity(newChild, modifiedAt: nil)

        node.updateEntityRelationship(childNode)

        XCTAssertEqual(node.value.singleNode, newChild)
    }

    func test_observeChild_childIsCollection_eachChildIsAdded() {
        let child1 = EntityNode(ListNodeFixture(id: 1), modifiedAt: startTimestamp)
        let child2 = EntityNode(ListNodeFixture(id: 2), modifiedAt: startTimestamp)
        let node = EntityNode(startEntity, modifiedAt: startTimestamp)

        XCTAssertEqual(node.metadata.childrenRefs.count, 0)

        node.observeChild(child1, for: \.listNodes[0])
        node.observeChild(child2, for: \.listNodes[1])

        XCTAssertEqual(node.metadata.childrenRefs.count, 2)
    }
}
