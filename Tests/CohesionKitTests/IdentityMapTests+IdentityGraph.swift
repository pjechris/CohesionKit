import XCTest
@testable import CohesionKit

class IdentityMapIdentityGraphTests: XCTestCase {
    func test_update_graphObjectIsStored() {
        let identityMap = IdentityMap<Date>()
        let graph = GraphTest(
            single: .init(id: 1, value: "single node"),
            children: [.init(id: 1, key: "child 1")]
        )

        _ = identityMap.update(graph, stamp: Date())

        XCTAssertEqual(identityMap.get(for: GraphTest.self, id: 1), graph)
    }

    func test_update_whenChildIsUpdated_graphObjectIsUpdated() {
        let expectation = XCTestExpectation()
        let identityMap = IdentityMap<Date>()
        let graph = GraphTest(
            single: .init(id: 1, value: "single node"),
            children: [.init(id: 1, key: "child 1")]
        )
        let childUpdate = GraphSingleChild(id: 1, value: "single node updated")

        _ = identityMap.update(graph, stamp: Date())
        _ = identityMap.update(childUpdate, stamp: Date().advanced(by: 1))

        expectation.isInverted = true
        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(identityMap.get(for: GraphSingleChild.self, id: 1), childUpdate)
        XCTAssertEqual(identityMap.get(for: GraphTest.self, id: 1)?.single, childUpdate)
    }

  func test_publisher_whenCanceled_noSubscriber_objectIsRemoved() {
    let identityMap = IdentityMap<Date>()
    let graph = GraphTest(
      single: .init(id: 1, value: "single node"),
      children: [.init(id: 1, key: "child 1")]
    )

    let publisher = identityMap.update(graph, stamp: Date())
    let cancellable = publisher.sink(receiveValue: { _ in })

    cancellable.cancel()

    XCTAssertNil(identityMap.get(for: GraphTest.self, id: 1))
  }
}

struct GraphTest: Equatable {
    let single: GraphSingleChild
    let children: [Graph]
}

struct GraphSingleChild: Identifiable, Equatable {
    let id: Int
    let value: String
}

struct Graph: Identifiable, Equatable {
    let id: Int
    let key: String
}

extension GraphTest: IdentityGraph {
    var idKeyPath: KeyPath<GraphTest, GraphSingleChild.ID> { \.single.id }

    var identityKeyPaths: [IdentityKeyPath<GraphTest>] { [.init(\.single), .init(\.children)] }

    func reduce(changes: IdentityValues<GraphTest>) -> GraphTest {
        GraphTest(single: changes.single, children: changes.children)
    }
}
