import XCTest
@testable import CohesionKit

class EntitiesStorageTests: XCTestCase {
    func test_get_objectWasSet_objectIsNotRetained_returnNil() {
        var indexer = EntitiesStorage()

        indexer[SingleNodeFixture.self, id: 1] = EntityNode(SingleNodeFixture(id: 1), modifiedAt: 0)

        XCTAssertNil(indexer[SingleNodeFixture.self, id: 1])
    }

    func test_get_objectWasSet_objectIsRetained_returnObject() {
        var indexer = EntitiesStorage()
        let entity = EntityNode(SingleNodeFixture(id: 1), modifiedAt: 0)

        indexer[SingleNodeFixture.self, id: 1] = entity

        XCTAssertEqual(indexer[SingleNodeFixture.self, id: 1], entity)
    }
}
