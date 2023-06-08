import XCTest
@testable import CohesionKit

class WeakStorageTests: XCTestCase {
    func test_get_objectWasSet_objectIsNotRetained_returnNil() {
        var storage = WeakStorage()

        storage[SingleNodeFixture.self, id: 1] = EntityNode(SingleNodeFixture(id: 1), modifiedAt: 0)

        XCTAssertNil(storage[SingleNodeFixture.self, id: 1])
    }

    func test_get_objectWasSet_objectIsRetained_returnObject() {
        var storage = WeakStorage()
        let entity = EntityNode(SingleNodeFixture(id: 1), modifiedAt: 0)

        storage[SingleNodeFixture.self, id: 1] = entity

        XCTAssertEqual(storage[SingleNodeFixture.self, id: 1], entity)
    }
}
