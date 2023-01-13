import XCTest
@testable import CohesionKit

class IdentityMapTests: XCTestCase {
    func test_storeAggregate_nestedEntitiesAreStored() {
        let entity = RootFixture(
            id: 1,
            primitive: "a",
            singleNode: .init(id: 1, primitive: "b"),
            optional: .init(id: 1),
            listNodes: [ListNodeFixture(id: 1)]
        )
        let identityMap = IdentityMap()

        withExtendedLifetime(identityMap.store(entity: entity)) { _ in
            XCTAssertNotNil(identityMap.storage[EntityNode<SingleNodeFixture>.self, id: 1])
            XCTAssertNotNil(identityMap.storage[EntityNode<OptionalNodeFixture>.self, id: 1])
            XCTAssertNotNil(identityMap.storage[EntityNode<ListNodeFixture>.self, id: 1])
        }
    }

    func test_nodeStoreAggregate_nestedOptionalReplacedByNil_previousOptionalIdentityChange_aggregateOptionalNotChanged() {
        let identityMap = IdentityMap()
        var nestedOptional = OptionalNodeFixture(id: 1)
        var root = RootFixture(id: 1, primitive: "", singleNode: SingleNodeFixture(id: 1), optional: nestedOptional, listNodes: [])
        var node: EntityNode<RootFixture> = identityMap.nodeStore(entity: root, modifiedAt: Date().stamp)

        root.optional = nil
        node = identityMap.nodeStore(entity: root, modifiedAt: Date().stamp)

        nestedOptional.properties = ["bla": "blob"]
        _ = identityMap.store(entity: nestedOptional)

        XCTAssertNil((node.value as! RootFixture).optional)
    }

    func test_nodeStoreAggregate_nestedArrayHasEntityRemoved_removedEntityChange_aggregateArrayNotChanged() {
        let identityMap = IdentityMap()
        var nestedArray: [ListNodeFixture] = [ListNodeFixture(id: 1), ListNodeFixture(id: 2)]
        var root = RootFixture(id: 1, primitive: "", singleNode: SingleNodeFixture(id: 1), optional: OptionalNodeFixture(id: 1), listNodes: nestedArray)
        var node: EntityNode<RootFixture> = identityMap.nodeStore(entity: root, modifiedAt: Date().stamp)

        nestedArray.removeLast()
        root.listNodes = nestedArray
        node = identityMap.nodeStore(entity: root, modifiedAt: Date().stamp)

        _ = identityMap.store(entity: ListNodeFixture(id: 2, key: "changed"))

        XCTAssertEqual((node.value as! RootFixture).listNodes, nestedArray)
    }

    func test_storeIdentifiable_entityIsInsertedForThe1stTime_loggerIsCalled() {
        let logger = LoggerMock()
        let identityMap = IdentityMap(logger: logger)
        let root = SingleNodeFixture(id: 1)
        let expectation = XCTestExpectation()

        logger.didStoreCalled = { _ in
            expectation.fulfill()
        }

        logger.didFailedCalled = { _ in
            XCTFail()
        }

        _ = identityMap.store(entity: root)

        wait(for: [expectation], timeout: 0.5)
    }

    func test_find_entityStored_noObserverAdded_returnNil() {
        let identityMap = IdentityMap()
        let entity = SingleNodeFixture(id: 1)

        _ = identityMap.store(entity: entity)

        XCTAssertNil(identityMap.find(SingleNodeFixture.self, id: 1))
    }

    func test_find_entityStored_observedAdded_subscriptionDeinit_returnNil() {
        let identityMap = IdentityMap()
        let entity = SingleNodeFixture(id: 1)

        // don't keep a direct ref to EntityObserver to check memory release management
        _ = identityMap.store(entity: entity).observe { _ in }

        XCTAssertNil(identityMap.find(SingleNodeFixture.self, id: 1))
    }

    func test_find_entityStored_observerAdded_returnEntity() {
        let identityMap = IdentityMap()
        let entity = SingleNodeFixture(id: 1)

        // don't keep a direct ref to EntityObserver to check memory release management
        withExtendedLifetime(identityMap.store(entity: entity).observe { _ in }) {
            XCTAssertEqual(identityMap.find(SingleNodeFixture.self, id: 1)?.value, entity)
        }
    }

    func test_findNamed_entityStored_subscriptionCancelled_returnValue() {
        let identityMap = IdentityMap()
        let entity = SingleNodeFixture(id: 1)

        _ = identityMap.store(entity: entity, named: .test)

        XCTAssertEqual(identityMap.find(named: .test).value, entity)
    }

    func test_findNamed_entityStored_thenRemoved_returnNil() {
        let identityMap = IdentityMap()
        let entity = SingleNodeFixture(id: 1)

        _ = identityMap.store(entity: entity, named: .test)
        identityMap.removeAlias(named: .test)

        XCTAssertNil(identityMap.find(named: .test).value)
    }

    func test_findNamed_aliasIsACollection_returnEntities() {
        let identityMap = IdentityMap()

        _ = identityMap.store(entities: [SingleNodeFixture(id: 1)], named: .listOfNodes)

        XCTAssertNotNil(identityMap.find(named: .listOfNodes).value)
    }

    func test_update_entityIsAlreadyInserted_entityIsUpdated() {
        let identityMap = IdentityMap()
        let entity = SingleNodeFixture(id: 1)

        withExtendedLifetime(identityMap.store(entity: entity)) { _ in
            _ = identityMap.update(SingleNodeFixture.self, id: 1) {
                $0.primitive = "hello"
            }

            XCTAssertEqual(identityMap.find(SingleNodeFixture.self, id: 1)?.value.primitive, "hello")
        }
    }

    func test_updateNamed_aliasIsExisting_existingObserversAreNotified() {
        let identityMap = IdentityMap(queue: .main)
        let entities = [SingleNodeFixture(id: 1)]
        let expectation = XCTestExpectation()

        _ = identityMap.find(named: .listOfNodes).observe {
            expectation.fulfill()
            XCTAssertEqual($0, entities)
        }

        _ = identityMap.update(named: .listOfNodes) {
            $0.append(contentsOf: entities)
        }
    }
}

private extension AliasKey where T == SingleNodeFixture {
    static let test = AliasKey(named: "test")
}

private extension AliasKey where T == [SingleNodeFixture] {
    static let listOfNodes = AliasKey(named: "listOfNodes")
}
