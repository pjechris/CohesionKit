import XCTest
@testable import CohesionKit

class AliasStorageTests: XCTestCase {
    func test_subscriptGet_aliasIsCollection_noValue_emptyAliasContainer() {
        var storage: AliasStorage = [:]

        XCTAssertNotNil(storage[key: .testCollection])
        XCTAssertNil(storage[key: .testCollection].ref.value.content)
    }

    func test_subscriptGet_aliasHasSameNameThanAnotherType_itReturnsAliasContainer() {
        var storage: AliasStorage = [:]
        let singleNode = EntityNode(AliasContainer(key: .test, content: 1), modifiedAt: 0)
        let collectionNode = EntityNode(AliasContainer(key: .testCollection, content: [2, 3]), modifiedAt: 0)

        storage[[Int].self, key: .testCollection] = collectionNode
        storage[Int.self, key: .test] = singleNode

        XCTAssertEqual(storage[key: .test], singleNode)
        XCTAssertEqual(storage[key: .testCollection], collectionNode)
    }
}

private extension AliasKey where T == Array<Int> {
    static let testCollection = AliasKey(named: "test")
}

private extension AliasKey where T == Int {
    static let test = AliasKey(named: "test")
}
