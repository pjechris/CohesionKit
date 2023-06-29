import XCTest
@testable import CohesionKit

class AliasStorageTests: XCTestCase {
    func test_subscriptGet_aliasIsCollection_noValue_returnObservable() {
        var storage: AliasStorage = [:]

        XCTAssertNotNil(storage[.testCollection])
        XCTAssertNil(storage[.testCollection].value)
    }

    func test_subscriptGet_twoAliasWithSameNameButDifferentType_returnBothCollections() {
        var storage: AliasStorage = [:]

        storage[.testCollection].value = [EntityNode(1, modifiedAt: 0), EntityNode(2, modifiedAt: 0)]
        storage[.test].value = EntityNode(3, modifiedAt: 0)

        XCTAssertEqual(storage.count, 2)
    }

    func test_subscriptGet_valueSet_returnValue() {
        var storage: AliasStorage = [:]
        let expectedValue = [EntityNode(1, modifiedAt: 0)]

        storage[.testCollection].value = expectedValue

        XCTAssertEqual(storage[.testCollection].value, expectedValue)
    }

    func test_remove_aliasInsertedBefore_itRemovesValue() {
        var storage: AliasStorage = [:]

        storage.insert(EntityNode(ref: Observable(value: 1), modifiedAt: nil), key: .test)
        storage.remove(for: .test)

        XCTAssertNil(storage[.test].value)
    }
}

private extension AliasKey where T == Array<Int> {
    static let testCollection = AliasKey(named: "test")
}

private extension AliasKey where T == Int {
    static let test = AliasKey(named: "test")
}
