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
    
    func test_storeAggregate_nestedOptionalReplacedByNil_previousOptionalIdentityChange_aggregateOptionalNotChanged() {
        let identityMap = IdentityMap()
        var nestedOptional = OptionalNodeFixture(id: 1)
        var root = RootFixture(id: 1, primitive: "", singleNode: SingleNodeFixture(id: 1), optional: nestedOptional, listNodes: [])
        var node: EntityNode<RootFixture> = identityMap.store(entity: root, modifiedAt: Date().stamp)
        
        root.optional = nil
        node = identityMap.store(entity: root, modifiedAt: Date().stamp)
        
        nestedOptional.properties = ["bla": "blob"]
        _ = identityMap.store(entity: nestedOptional)
        
        XCTAssertNil((node.value as! RootFixture).optional)
    }
    
    func test_storeAggregate_nestedArrayHasEntityRemoved_removedEntityChange_aggregateArrayNotChanged() {
        let identityMap = IdentityMap()
        var nestedArray: [ListNodeFixture] = [ListNodeFixture(id: 1), ListNodeFixture(id: 2)]
        var root = RootFixture(id: 1, primitive: "", singleNode: SingleNodeFixture(id: 1), optional: OptionalNodeFixture(id: 1), listNodes: nestedArray)
        var node: EntityNode<RootFixture> = identityMap.store(entity: root, modifiedAt: Date().stamp)
        
        nestedArray.removeLast()
        root.listNodes = nestedArray
        node = identityMap.store(entity: root, modifiedAt: Date().stamp)
        
        _ = identityMap.store(entity: ListNodeFixture(id: 2, key: "changed"))
        
        XCTAssertEqual((node.value as! RootFixture).listNodes, nestedArray)
    }

}
