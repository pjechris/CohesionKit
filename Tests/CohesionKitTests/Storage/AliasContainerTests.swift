import XCTest
@testable import CohesionKit

class AliasContainerTests: XCTestCase {
    func test_nestedEntitiesKeyPaths_contentIsAggregate_itContainsContent() {
        let container = AliasContainer(
            key: .aggregateContainerTest,
            content: RootFixture(id: 1, primitive: "", singleNode: .init(id: 1), listNodes: [])
        )

        XCTAssertEqual(container.nestedEntitiesKeyPaths.count, 1)
        XCTAssertEqual(container.nestedEntitiesKeyPaths[0].keyPath, \AliasContainer<RootFixture>.content)
    }

    func test_nestedEntitiesKeyPaths_contentIsIdentifiable_itContainsContent() {
        let container = AliasContainer(
            key: .identifiableContainerTests,
            content: SingleNodeFixture(id: 1)
        )

        XCTAssertEqual(container.nestedEntitiesKeyPaths.count, 1)
        XCTAssertEqual(container.nestedEntitiesKeyPaths[0].keyPath, \AliasContainer<SingleNodeFixture>.content)
    }

    func test_nestedEntitiesKeyPaths_contentIsArrayAggregate_itContainsContent() {
        let container = AliasContainer(
            key: .arrayAggregateContainerTests,
            content: [RootFixture(id: 1, primitive: "", singleNode: .init(id: 1), listNodes: [])]
        )

        XCTAssertEqual(container.nestedEntitiesKeyPaths.count, 1)
        XCTAssertEqual(container.nestedEntitiesKeyPaths[0].keyPath, \AliasContainer<[RootFixture]>.content)
    }

    func test_nestedEntitiesKeyPaths_contentIsArrayIdentifiable_itContainsContent() {
        let container = AliasContainer(
            key: .arrayIdentifiableContainerTests,
            content: [SingleNodeFixture(id: 1)]
        )

        XCTAssertEqual(container.nestedEntitiesKeyPaths.count, 1)
        XCTAssertEqual(container.nestedEntitiesKeyPaths[0].keyPath, \AliasContainer<[SingleNodeFixture]>.content)
    }
}

extension AliasKey where T == RootFixture {
    fileprivate static let aggregateContainerTest = AliasKey(named: "aggregate")
}

extension AliasKey where T == SingleNodeFixture {
    fileprivate static let identifiableContainerTests = AliasKey(named: "identifiable")
}

extension AliasKey where T == [SingleNodeFixture] {
    fileprivate static let arrayIdentifiableContainerTests = AliasKey(named: "identifiable")
}

extension AliasKey where T == [RootFixture] {
    fileprivate static let arrayAggregateContainerTests = AliasKey(named: "aggregate")
}