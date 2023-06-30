import XCTest
@testable import CohesionKit

// MARK: Store
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
            XCTAssertNotNil(identityMap.storage[SingleNodeFixture.self, id: 1])
            XCTAssertNotNil(identityMap.storage[OptionalNodeFixture.self, id: 1])
            XCTAssertNotNil(identityMap.storage[ListNodeFixture.self, id: 1])
        }
    }

    func test_nodeStoreAggregate_nestedOptionalReplacedByNil_previousOptionalIdentityChange_nestedOptionalRemainsNil() {
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

    func test_storeIdentifiable_entityIsAlreadyStore_updateIsCalled() {
        let root = SingleNodeFixture(id: 1)
        let identityMap = IdentityMap()
        let expectation = XCTestExpectation()

        _ = withExtendedLifetime(identityMap.store(entity: root)) {
            _ = identityMap.store(entity: root, ifPresent: { _ in
                expectation.fulfill()
            })
        }

        wait(for: [expectation], timeout: 0)
    }
}

// MARK: Find
extension IdentityMapTests {
    func test_find_entityStored_noObserverAdded_returnNil() {
        let identityMap = IdentityMap()
        let entity = SingleNodeFixture(id: 1)

        _ = identityMap.store(entity: entity)

        XCTAssertNil(identityMap.find(SingleNodeFixture.self, id: 1))
    }

    func test_find_entityStored_observedAdded_subscriptionIsReleased_returnNil() {
        let identityMap = IdentityMap()
        let entity = SingleNodeFixture(id: 1)

        // don't keep a direct ref to EntityObserver to check memory release management
        _ = identityMap.store(entity: entity).observe { _ in }

        XCTAssertNil(identityMap.find(SingleNodeFixture.self, id: 1))
    }

    func test_find_entityStored_observerAdded_returnEntity() {
        let identityMap = IdentityMap()
        let entity = SingleNodeFixture(id: 1)

        withExtendedLifetime(identityMap.store(entity: entity).observe { _ in }) {
            XCTAssertEqual(identityMap.find(SingleNodeFixture.self, id: 1)?.value, entity)
        }
    }

    func test_find_entityStored_entityUpdatedByAnAggregate_returnUpdatedEntity() {
        let identityMap = IdentityMap()
        let entity = SingleNodeFixture(id: 1)
        let update = SingleNodeFixture(id: 1, primitive: "Updated by Aggregate")

        withExtendedLifetime(identityMap.store(entity: entity).observe { _ in }) {
            _ = identityMap.store(entity: RootFixture(id: 1, primitive: "", singleNode: update, listNodes: []))

            XCTAssertEqual(identityMap.find(SingleNodeFixture.self, id: 1)?.value, update)
        }
    }

    func test_find_entityStored_aggregateUpdateEntity_observerReturnUpdatedValue() {
        let identityMap = IdentityMap()
        let entity = SingleNodeFixture(id: 1)
        let update = SingleNodeFixture(id: 1, primitive: "Updated by Aggregate")
        let insertion = identityMap.store(entity: entity)

        let subscription = insertion.observe {
            XCTAssertEqual($0, update)
        }

        withExtendedLifetime(subscription) {
            _ = identityMap.store(entity: RootFixture(id: 1, primitive: "", singleNode: update, listNodes: []))
        }
    }

    func test_findNamed_entityStored_noObserver_returnValue() {
        let identityMap = IdentityMap()
        let entity = SingleNodeFixture(id: 1)

        _ = identityMap.store(entity: entity, named: .test)

        XCTAssertEqual(identityMap.find(named: .test).value, entity)
    }

    func test_findNamed_allAliasRemoved_returnNil() {
        let identityMap = IdentityMap(queue: .main)

        _ = identityMap.store(entity: SingleNodeFixture(id: 1), named: .test, modifiedAt: 0)

        XCTAssertNotNil(identityMap.find(named: .test).value)

        identityMap.removeAllAlias()

        XCTAssertNil(identityMap.find(named: .test).value)
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
}

// MARK: Update

extension IdentityMapTests {

    func test_update_entityIsAlreadyInserted_entityIsUpdated() {
        let identityMap = IdentityMap()
        let entity = SingleNodeFixture(id: 1)

        withExtendedLifetime(identityMap.store(entity: entity)) { _ in
            identityMap.update(SingleNodeFixture.self, id: 1) {
                $0.primitive = "hello"
            }

            XCTAssertEqual(identityMap.find(SingleNodeFixture.self, id: 1)?.value.primitive, "hello")
        }
    }

    func test_updateNamed_entityIsIdentifiable_aliasIsExisting_observersAreNotified() {
        let identityMap = IdentityMap(queue: .main)
        let newEntity = SingleNodeFixture(id: 2)
        let expectation = XCTestExpectation()

        _ = identityMap.store(entity: SingleNodeFixture(id: 1), named: .test, modifiedAt: 0)

        let subscription = identityMap.find(named: .test).observe {
            expectation.fulfill()
            XCTAssertEqual($0, newEntity)
        }

        withExtendedLifetime(subscription) {
            identityMap.update(named: .test, modifiedAt: 1) {
                $0 = newEntity
            }

            wait(for: [expectation], timeout: 0.5)
        }
    }

    func test_updateNamed_entityIsCollection_aliasIsExisting_observersAreNotified() {
        let identityMap = IdentityMap(queue: .main)
        let entities = [SingleNodeFixture(id: 1)]
        let expectation = XCTestExpectation()

        _ = identityMap.store(entities: [], named: .listOfNodes, modifiedAt: 0)

        let subscription = identityMap.find(named: .listOfNodes).observe {
            expectation.fulfill()
            XCTAssertEqual($0, entities)
        }

        withExtendedLifetime(subscription) {
            identityMap.update(named: .listOfNodes, modifiedAt: 1) {
                $0.append(contentsOf: entities)
            }

            wait(for: [expectation], timeout: 0.5)
        }
    }
}

private extension AliasKey where T == SingleNodeFixture {
    static let test = AliasKey(named: "test")
}

private extension AliasKey where T == [SingleNodeFixture] {
    static let listOfNodes = AliasKey(named: "listOfNodes")
}
