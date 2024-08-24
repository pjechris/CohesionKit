import XCTest
@testable import CohesionKit

class EntityStoreTests: XCTestCase {
    // MARK: Store Aggregate
    func test_storeAggregate_nestedEntitiesAreStored() {
        let entity = RootFixture(
            id: 1,
            primitive: "a",
            singleNode: .init(id: 1, primitive: "b"),
            optional: .init(id: 1),
            listNodes: [ListNodeFixture(id: 1)]
        )
        let entityStore = EntityStore()

        withExtendedLifetime(entityStore.store(entity: entity)) { _ in
            XCTAssertNotNil(entityStore.find(SingleNodeFixture.self, id: 1))
            XCTAssertNotNil(entityStore.find(OptionalNodeFixture.self, id: 1))
            XCTAssertNotNil(entityStore.find(ListNodeFixture.self, id: 1))
        }
    }

    func test_storeAggregate_nestedEntitySetToNil_entityIsUpdated_aggregateNestedEntityRemainsNil() throws {
        let entityStore = EntityStore()
        let nestedOptional = OptionalNodeFixture(id: 1)
        var root = RootFixture(id: 1, primitive: "", singleNode: SingleNodeFixture(id: 1), optional: nestedOptional, listNodes: [])

        try withExtendedLifetime(entityStore.store(entity: root)) {
            root.optional = nil

            _ = entityStore.store(entity: root)
            _ = entityStore.store(entity: nestedOptional)

            let root = try XCTUnwrap(entityStore.find(RootFixture.self, id: 1))
            XCTAssertNil(root.value.optional)
        }
    }

    /// check that removed relations do not trigger an update
    func test_storeAggregate_removeEntityFromNestedArray_removedEntityChange_aggregateArrayNotChanged() throws {
        let entityStore = EntityStore()
        var entityToRemove = ListNodeFixture(id: 2)
        let nestedArray: [ListNodeFixture] = [entityToRemove, ListNodeFixture(id: 1)]
        var root = RootFixture(id: 1, primitive: "", singleNode: SingleNodeFixture(id: 1), optional: OptionalNodeFixture(id: 1), listNodes: nestedArray)

        try withExtendedLifetime(entityStore.store(entity: root)) {
            root.listNodes = Array(nestedArray[1...])
            entityToRemove.key = "changed"

            _ = entityStore.store(entity: root)
            _ = entityStore.store(entity: entityToRemove)

            let root = try XCTUnwrap(entityStore.find(RootFixture.self, id: 1))

            XCTAssertFalse(root.value.listNodes.contains(entityToRemove))
            XCTAssertFalse(root.value.listNodes.map(\.id).contains(entityToRemove.id))
        }
    }

    func test_storeAggregate_nestedWrapperChanged_aggregateIsUpdated() throws {
        let entityStore = EntityStore()
        let root = RootFixture(id: 1, primitive: "", singleNode: SingleNodeFixture(id: 1), optional: OptionalNodeFixture(id: 1), listNodes: [], enumWrapper: .single(SingleNodeFixture(id: 2)))
        let updatedValue = SingleNodeFixture(id: 2, primitive: "updated")

        try withExtendedLifetime(entityStore.store(entity: root)) {
            _ = entityStore.store(entity: updatedValue)
            let root = try XCTUnwrap(entityStore.find(RootFixture.self, id: 1))
            XCTAssertEqual(root.value.enumWrapper, .single(updatedValue))
        }
    }

    func test_storeAggregate_nestedOptionalWrapperNullified_aggregateIsNullified() throws {
        let entityStore = EntityStore()
        var root = RootFixture(id: 1, primitive: "", singleNode: SingleNodeFixture(id: 1), optional: OptionalNodeFixture(id: 1), listNodes: [], enumWrapper: .single(SingleNodeFixture(id: 2)))

        try withExtendedLifetime(entityStore.store(entity: root)) {
            root.enumWrapper = nil

            _ = entityStore.store(entity: root)
            _ = entityStore.store(entity: SingleNodeFixture(id: 2, primitive: "deleted"))

            let root = try XCTUnwrap(entityStore.find(RootFixture.self, id: 1))
            XCTAssertNil(root.value.enumWrapper)
        }
    }

    func test_storeAggregate_registryContainsModifiedEntities() {
        let registryStub = ObserverRegistryStub(queue: .main)
        let entityStore = EntityStore(registry: registryStub)
        let root = RootFixture(id: 1, primitive: "", singleNode: SingleNodeFixture(id: 1), optional: OptionalNodeFixture(id: 1), listNodes: [], enumWrapper: .single(SingleNodeFixture(id: 2)))

        withExtendedLifetime(entityStore.store(entity: root)) {
            XCTAssertTrue(registryStub.hasPendingChange(for: root))
            XCTAssertTrue(registryStub.hasPendingChange(for: SingleNodeFixture(id: 1)))
            XCTAssertTrue(registryStub.hasPendingChange(for: SingleNodeFixture(id: 2)))
            XCTAssertTrue(registryStub.hasPendingChange(for: OptionalNodeFixture(id: 1)))
        }
    }

    func test_storeAggregate_named_itEnqueuesAliasInRegistry() {
        let root = SingleNodeFixture(id: 1)
        let registry = ObserverRegistryStub()
        let entityStore = EntityStore(registry: registry)

        withExtendedLifetime(entityStore.store(entity: root, named: .test)) {
            XCTAssertTrue(registry.hasPendingChange(for: AliasContainer<SingleNodeFixture>.self))
            XCTAssertTrue(registry.hasPendingChange(for: SingleNodeFixture.self))
        }
    }
}

// MARK: Store Entities
extension EntityStoreTests {
    /// make sure when inserting multiple time the same entity that it actually gets inserted only once
    func test_storeEntities_sameEntityPresentMultipleTimes_itIsInsertedOnce() {
        let registry = ObserverRegistryStub(queue: .main)
        let entityStore = EntityStore(registry: registry)
        let commonEntity = SingleNodeFixture(id: 1)
        let root1 = RootFixture(id: 1, primitive: "", singleNode: commonEntity, optional: OptionalNodeFixture(id: 1), listNodes: [], enumWrapper: .single(SingleNodeFixture(id: 2)))
        let root2 = RootFixture(id: 1, primitive: "", singleNode: commonEntity, optional: OptionalNodeFixture(id: 1), listNodes: [], enumWrapper: nil)

        _ = entityStore.store(entities: [root1, root2])

        XCTAssertEqual(registry.pendingChangeCount(for: commonEntity), 1)
    }

    func test_storeEntities_named_calledMultipleTimes_lastValueIsStored() {
        let entityStore = EntityStore()
        let root = SingleNodeFixture(id: 1)
        let root2 = SingleNodeFixture(id: 2)

        _ = entityStore.store(entities: [root], named: .listOfNodes)
        _ = entityStore.store(entities: [root, root2], named: .listOfNodes)

        XCTAssertEqual(entityStore.find(named: .listOfNodes).value, [root, root2])
    }
}

// MARK: Store Identifiable
extension EntityStoreTests {
    func test_storeIdentifiable_entityIsInsertedForThe1stTime_loggerIsCalled() {
        let logger = LoggerMock()
        let entityStore = EntityStore(logger: logger)
        let root = SingleNodeFixture(id: 1)
        let expectation = XCTestExpectation()

        logger.didStoreCalled = { _ in
            expectation.fulfill()
        }

        logger.didFailedCalled = { _ in
            XCTFail()
        }

        _ = entityStore.store(entity: root)

        wait(for: [expectation], timeout: 0.5)
    }

//    func test_storeIdentifiable_entityIsAlreadyStored_updateIsCalled() {
//        let root = SingleNodeFixture(id: 1)
//        let entityStore = EntityStore()
//        let expectation = XCTestExpectation()
//
//        withExtendedLifetime(entityStore.store(entity: root)) {
//            _ = entityStore.store(entity: root, ifPresent: { _ in
//                expectation.fulfill()
//            })
//        }
//
//        wait(for: [expectation], timeout: 0)
//    }
}

// MARK: Find
extension EntityStoreTests {
    func test_find_entityStored_noObserverAdded_returnNil() {
        let entityStore = EntityStore()
        let entity = SingleNodeFixture(id: 1)

        _ = entityStore.store(entity: entity)

        XCTAssertNil(entityStore.find(SingleNodeFixture.self, id: 1))
    }

    func test_find_entityStored_observedAdded_subscriptionIsReleased_returnNil() {
        let entityStore = EntityStore()
        let entity = SingleNodeFixture(id: 1)

        // don't keep a direct ref to EntityObserver to check memory release management
        _ = entityStore.store(entity: entity).observe { _ in }

        XCTAssertNil(entityStore.find(SingleNodeFixture.self, id: 1))
    }

    func test_find_entityStored_observerAdded_returnEntity() {
        let entityStore = EntityStore()
        let entity = SingleNodeFixture(id: 1)

        withExtendedLifetime(entityStore.store(entity: entity).observe { _ in }) {
            XCTAssertEqual(entityStore.find(SingleNodeFixture.self, id: 1)?.value, entity)
        }
    }

    func test_find_entityStored_entityUpdatedByAnAggregate_returnUpdatedEntity() {
        let entityStore = EntityStore()
        let entity = SingleNodeFixture(id: 1)
        let update = SingleNodeFixture(id: 1, primitive: "Updated by Aggregate")

        let subscription = entityStore.store(entity: entity).observe { _ in }

        withExtendedLifetime(subscription) {
            _ = entityStore.store(entity: RootFixture(id: 1, primitive: "", singleNode: update, listNodes: []))

            XCTAssertEqual(entityStore.find(SingleNodeFixture.self, id: 1)?.value, update)
        }
    }

    func test_find_entityStored_aggregateUpdateEntity_observerReturnUpdatedValue() {
        let entityStore = EntityStore()
        let entity = SingleNodeFixture(id: 1)
        let update = SingleNodeFixture(id: 1, primitive: "Updated by Aggregate")
        let insertion = entityStore.store(entity: entity)
        var firstDropped = false

        let subscription = insertion.observe {
            guard firstDropped else {
                firstDropped = true
                return
            }

            XCTAssertEqual($0, update)
        }

        withExtendedLifetime(subscription) {
            _ = entityStore.store(entity: RootFixture(id: 1, primitive: "", singleNode: update, listNodes: []))
        }
    }

    func test_find_storedByAliasCollection_itReturnsEntity() {
        let entityStore = EntityStore()

        _ = entityStore.store(entities: [SingleNodeFixture(id: 1)], named: .listOfNodes)

        XCTAssertNotNil(entityStore.find(SingleNodeFixture.self, id: 1))
    }

    func test_find_storedByAliasAggregate_itReturnsEntity() {
        let entityStore = EntityStore()
        let aggregate = RootFixture(id: 1, primitive: "", singleNode: SingleNodeFixture(id: 1), listNodes: [])

        _ = entityStore.store(entity: aggregate, named: .root)

        XCTAssertNotNil(entityStore.find(SingleNodeFixture.self, id: 1))
    }

    func test_findNamed_entityStored_noObserver_returnValue() {
        let entityStore = EntityStore()
        let entity = SingleNodeFixture(id: 1)

        _ = entityStore.store(entity: entity, named: .test)

        XCTAssertEqual(entityStore.find(named: .test).value, entity)
    }

    func test_findNamed_allAliasRemoved_returnNil() {
        let entityStore = EntityStore(queue: .main)

        _ = entityStore.store(entity: SingleNodeFixture(id: 1), named: .test, modifiedAt: 0)

        XCTAssertNotNil(entityStore.find(named: .test).value)

        entityStore.removeAllAlias()

        XCTAssertNil(entityStore.find(named: .test).value)
    }

    func test_findNamed_entityStored_thenRemoved_returnNil() {
        let entityStore = EntityStore()
        let entity = SingleNodeFixture(id: 1)

        _ = entityStore.store(entity: entity, named: .test)
        entityStore.removeAlias(named: .test)

        XCTAssertNil(entityStore.find(named: .test).value)
    }

    func test_findNamed_aliasIsACollection_returnEntities() {
        let entityStore = EntityStore()

        _ = entityStore.store(entities: [SingleNodeFixture(id: 1)], named: .listOfNodes)

        XCTAssertNotNil(entityStore.find(named: .listOfNodes).value)
    }
}

// MARK: Update

extension EntityStoreTests {

    func test_update_entityIsAlreadyInserted_entityIsUpdated() {
        let entityStore = EntityStore()
        let entity = SingleNodeFixture(id: 1)

        withExtendedLifetime(entityStore.store(entity: entity)) { _ in
            entityStore.update(SingleNodeFixture.self, id: 1) {
                $0.primitive = "hello"
            }

            XCTAssertEqual(entityStore.find(SingleNodeFixture.self, id: 1)?.value.primitive, "hello")
        }
    }

    func test_updateNamed_entityIsIdentifiable_aliasIsExisting_observersAreNotified() {
        let entityStore = EntityStore(queue: .main)
        let newEntity = SingleNodeFixture(id: 2)
        let expectation = XCTestExpectation()
        var firstDropped = false

        _ = entityStore.store(entity: SingleNodeFixture(id: 1), named: .test, modifiedAt: 0)

        let subscription = entityStore.find(named: .test).observe {
            guard firstDropped else {
                firstDropped = true
                return
            }

            expectation.fulfill()
            XCTAssertEqual($0, newEntity)
        }

        withExtendedLifetime(subscription) {
            entityStore.update(named: .test, modifiedAt: 1) {
                $0 = newEntity
            }

            wait(for: [expectation], timeout: 0.5)
        }
    }

    func test_updateNamed_entityIsCollection_aliasIsExisting_observersAreNotified() {
        let entityStore = EntityStore(queue: .main)
        let entities = [SingleNodeFixture(id: 1)]
        let expectation = XCTestExpectation()
        var firstDropped = false

        _ = entityStore.store(entities: [], named: .listOfNodes, modifiedAt: 0)

        let subscription = entityStore.find(named: .listOfNodes).observe {
            guard firstDropped else {
                firstDropped = true
                return
            }

            expectation.fulfill()
            XCTAssertEqual($0, entities)
        }

        withExtendedLifetime(subscription) {
            entityStore.update(named: .listOfNodes, modifiedAt: 1) {
                $0.append(contentsOf: entities)
            }

            wait(for: [expectation], timeout: 0.5)
        }
    }

    func test_updateNamed_entityIsAggregate_itEnqueuesNestedObjectsInRegistry() {
        let registry = ObserverRegistryStub()
        let entityStore = EntityStore(registry: registry)
        let initialValue = RootFixture(
            id: 1,
            primitive: "",
            singleNode: .init(id: 1),
            listNodes: []
        )
        let singleNodeUpdate = SingleNodeFixture(id: 1, primitive: "update")

        _ = entityStore.store(entity: initialValue, named: .root)

        registry.clearPendingChangesStub()

        entityStore.update(named: .root) {
            $0.singleNode = singleNodeUpdate
        }

        XCTAssertTrue(registry.hasPendingChange(for: singleNodeUpdate))
    }

    func test_updateNamed_aliasIsAggregate_itEnqueuesAliasInRegistry() {
        let registry = ObserverRegistryStub()
        let entityStore = EntityStore(registry: registry)
        let initialValue = RootFixture(
            id: 1,
            primitive: "",
            singleNode: .init(id: 1),
            listNodes: []
        )
        let singleNodeUpdate = SingleNodeFixture(id: 1, primitive: "update")

        _ = entityStore.store(entity: initialValue, named: .root)

        registry.clearPendingChangesStub()

        entityStore.update(named: .root) {
            $0.singleNode = singleNodeUpdate
        }

        XCTAssertTrue(registry.hasPendingChange(for: AliasContainer<RootFixture>.self))
    }

    func test_update_entityIsIndirectlyUsedByAlias_itEnqueuesAliasInRegistry() {
        let aggregate = RootFixture(id: 1, primitive: "", singleNode: SingleNodeFixture(id: 1), listNodes: [])
        let registry = ObserverRegistryStub()
        let entityStore = EntityStore(registry: registry)

        _ = entityStore.store(entities: [aggregate], named: .rootList)

        registry.clearPendingChangesStub()

        entityStore.update(SingleNodeFixture.self, id: 1) {
            $0.primitive = "updated"
        }

        XCTAssertTrue(registry.hasPendingChange(for: AliasContainer<[RootFixture]>.self))
    }
}

// MARK: Remove
extension EntityStoreTests {
    func test_removeAlias_itEnqueuesNilInRegistry() {
        let registry = ObserverRegistryStub()
        let store = EntityStore(registry: registry)

        _ = store.store(entity: SingleNodeFixture(id: 1), named: .test)

        registry.clearPendingChangesStub()

        store.removeAlias(named: .test)

        XCTAssertTrue(registry.hasPendingChange(for: AliasContainer(key: .test, content: nil)))
    }

    func test_removeAllAlias_itEnqueuesNilForEachAlias() {
        let registry = ObserverRegistryStub()
        let store = EntityStore(registry: registry)

        _ = store.store(entity: SingleNodeFixture(id: 1), named: .test)
        _ = store.store(entities: [SingleNodeFixture(id: 2)], named: .listOfNodes)

        registry.clearPendingChangesStub()

        store.removeAllAlias()

        XCTAssertTrue(registry.hasPendingChange(for: AliasContainer(key: .test, content: nil)))
        XCTAssertTrue(registry.hasPendingChange(for: AliasContainer(key: .listOfNodes, content: nil)))
    }
}

private extension AliasKey where T == SingleNodeFixture {
    static let test = AliasKey(named: "test")
}

private extension AliasKey where T == [SingleNodeFixture] {
    static let listOfNodes = AliasKey(named: "listOfNodes")
}

private extension AliasKey where T == RootFixture {
    static let root = AliasKey(named: "root")
}

private extension AliasKey where T == [RootFixture] {
    static let rootList = AliasKey(named: "root")
}
