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

    func test_storeAggregate_nestedEntityReplacedByNil_entityIsUpdated_aggregateEntityRemainsNil() {
        let identityMap = IdentityMap()
        let nestedOptional = OptionalNodeFixture(id: 1)
        var root = RootFixture(id: 1, primitive: "", singleNode: SingleNodeFixture(id: 1), optional: nestedOptional, listNodes: [])

        withExtendedLifetime(identityMap.store(entity: root)) {
            root.optional = nil

            _ = identityMap.store(entity: root)
            _ = identityMap.store(entity: nestedOptional)

            XCTAssertNotNil(identityMap.find(RootFixture.self, id: 1))
            XCTAssertNil(identityMap.find(RootFixture.self, id: 1)!.value.optional)
        }
    }

    /// check that removed relations do not trigger an update
    func test_storeAggregate_removeEntityFromNestedArray_removedEntityChange_aggregateArrayNotChanged() {
        let identityMap = IdentityMap()
        var entityToRemove = ListNodeFixture(id: 2)
        let nestedArray: [ListNodeFixture] = [entityToRemove, ListNodeFixture(id: 1)]
        var root = RootFixture(id: 1, primitive: "", singleNode: SingleNodeFixture(id: 1), optional: OptionalNodeFixture(id: 1), listNodes: nestedArray)

        withExtendedLifetime(identityMap.store(entity: root)) {
            root.listNodes = Array(nestedArray[1...])
            entityToRemove.key = "changed"

            _ = identityMap.store(entity: root)
            _ = identityMap.store(entity: entityToRemove)

            let storedRoot = identityMap.find(RootFixture.self, id: 1)!.value

            XCTAssertFalse(storedRoot.listNodes.contains(entityToRemove))
            XCTAssertFalse(storedRoot.listNodes.map(\.id).contains(entityToRemove.id))
        }
    }

    func test_storeAggregate_nestedWrapperChanged_aggregateIsUpdated() {
        let identityMap = IdentityMap()
        let root = RootFixture(id: 1, primitive: "", singleNode: SingleNodeFixture(id: 1), optional: OptionalNodeFixture(id: 1), listNodes: [], enumWrapper: .single(SingleNodeFixture(id: 2)))
        let updatedValue = SingleNodeFixture(id: 2, primitive: "updated")

        withExtendedLifetime(identityMap.store(entity: root)) {
            _ = identityMap.store(entity: updatedValue)
            XCTAssertEqual(identityMap.find(RootFixture.self, id: 1)!.value.enumWrapper, .single(updatedValue))
        }
    }

    func test_storeAggregate_nestedOptionalWrapperNullified_aggregateIsNullified() {
        let identityMap = IdentityMap()
        var root = RootFixture(id: 1, primitive: "", singleNode: SingleNodeFixture(id: 1), optional: OptionalNodeFixture(id: 1), listNodes: [], enumWrapper: .single(SingleNodeFixture(id: 2)))

        withExtendedLifetime(identityMap.store(entity: root)) {
            root.enumWrapper = nil

            _ = identityMap.store(entity: root)
            _ = identityMap.store(entity: SingleNodeFixture(id: 2, primitive: "deleted"))

            XCTAssertNil(identityMap.find(RootFixture.self, id: 1)!.value.enumWrapper)
        }
    }

    func test_storeAggregate_registryContainsModifiedEntities() {
        let registryStub = ObserverRegistryStub(queue: .main)
        let identityMap = IdentityMap(registry: registryStub)
        let root = RootFixture(id: 1, primitive: "", singleNode: SingleNodeFixture(id: 1), optional: OptionalNodeFixture(id: 1), listNodes: [], enumWrapper: .single(SingleNodeFixture(id: 2)))

        withExtendedLifetime(identityMap.store(entity: root)) {
            XCTAssertTrue(registryStub.hasPendingChange(for: root))
            XCTAssertTrue(registryStub.hasPendingChange(for: SingleNodeFixture(id: 1)))
            XCTAssertTrue(registryStub.hasPendingChange(for: SingleNodeFixture(id: 2)))
            XCTAssertTrue(registryStub.hasPendingChange(for: OptionalNodeFixture(id: 1)))
        }
    }

    /// make sure when inserting multiple time the same entity that it actually gets inserted only once
    func test_storeEntities_sameEntityPresentMultipleTimes_itIsInsertedOnce() {
        let registry = ObserverRegistryStub(queue: .main)
        let identityMap = IdentityMap(registry: registry)
        let commonEntity = SingleNodeFixture(id: 1)
        let root1 = RootFixture(id: 1, primitive: "", singleNode: commonEntity, optional: OptionalNodeFixture(id: 1), listNodes: [], enumWrapper: .single(SingleNodeFixture(id: 2)))
        let root2 = RootFixture(id: 1, primitive: "", singleNode: commonEntity, optional: OptionalNodeFixture(id: 1), listNodes: [], enumWrapper: nil)

        _ = identityMap.store(entities: [root1, root2])

        XCTAssertEqual(registry.pendingChangeCount(for: commonEntity), 1)
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

    func test_storeIdentifiable_entityIsAlreadyStored_updateIsCalled() {
        let root = SingleNodeFixture(id: 1)
        let identityMap = IdentityMap()
        let expectation = XCTestExpectation()

        withExtendedLifetime(identityMap.store(entity: root)) {
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

        let subscription = identityMap.store(entity: entity).observe { _ in }

        withExtendedLifetime(subscription) {
            _ = identityMap.store(entity: RootFixture(id: 1, primitive: "", singleNode: update, listNodes: []))

            XCTAssertEqual(identityMap.find(SingleNodeFixture.self, id: 1)?.value, update)
        }
    }

    func test_find_entityStored_aggregateUpdateEntity_observerReturnUpdatedValue() {
        let identityMap = IdentityMap()
        let entity = SingleNodeFixture(id: 1)
        let update = SingleNodeFixture(id: 1, primitive: "Updated by Aggregate")
        let insertion = identityMap.store(entity: entity)
        var firstDropped = false

        let subscription = insertion.observe {
            guard firstDropped else {
                firstDropped = true
                return
            }

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