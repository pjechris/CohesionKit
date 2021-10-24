import XCTest
import CohesionKit
import Combine

class IdentityMapRelationalTests: XCTestCase {
    func test_update_graphObjectIsStored() {
        let identityMap = IdentityMap()
        let graph = GraphTest(
            single: .init(id: 1, value: "single node"),
            children: [.init(id: 1, key: "child 1")]
        )

        _ = identityMap.store(graph, using: Relations.graphTest)

        XCTAssertEqual(identityMap.get(using: Relations.graphTest, id: 1), graph)
    }

    func test_store_whenChildIsUpdated_graphObjectIsUpdated() {
        let expectation = XCTestExpectation(description: "wait for updates")
        let identityMap = IdentityMap()
        let graph = GraphTest(
            single: .init(id: 1, value: "single node"),
            children: [.init(id: 1, key: "child 1")]
        )
        let childUpdate = GraphSingleChild(id: 1, value: "single node updated")

        _ = identityMap.store(graph, using: Relations.graphTest)
        _ = identityMap.store(childUpdate, modifiedAt: Date().advanced(by: 1).stamp)

        expectation.isInverted = true
        wait(for: [expectation], timeout: 0.5)

        XCTAssertEqual(identityMap.get(for: GraphSingleChild.self, id: 1), childUpdate)
        XCTAssertEqual(identityMap.get(using: Relations.graphTest, id: 1)?.single, childUpdate)
    }

  func test_publisher_whenCanceled_noSubscriber_objectIsRemoved() {
    let identityMap = IdentityMap()
    let graph = GraphTest(
      single: .init(id: 1, value: "single node"),
      children: [.init(id: 1, key: "child 1")]
    )

    let publisher = identityMap.store(graph, using: Relations.graphTest)
    let cancellable = publisher.sink(receiveValue: { _ in })

    cancellable.cancel()

    XCTAssertNil(identityMap.get(using: Relations.graphTest, id: 1))
  }
    
    func test_publisherForId_childrenAreUpdatedAsBatch_oneUpdateIsSent() {
        let identityMap = IdentityMap()
        let expectation = XCTestExpectation()
        let id = 1
        let updates = [
            Graph(id: 1, key: "Hello1"),
            Graph(id: 2, key: "Hello2"),
            Graph(id: 3, key: "Hello3")
        ]
        let graph =
            GraphTest(
                single: GraphSingleChild(id: id, value: "Single"),
                children: [
                    Graph(id: 1, key: "Child1"),
                    Graph(id: 2, key: "Child2"),
                    Graph(id: 3, key: "Child3"),
                ]
            )
        var receivedValueCount = 0
        var cancellables: Set<AnyCancellable> = []
        
        _ = identityMap.store(graph, using: Relations.graphTest)
        
        identityMap
            .publisher(using: Relations.graphTest, id: id)
            .sink(receiveValue: { _ in receivedValueCount += 1 })
            .store(in: &cancellables)
        
        _ = identityMap.store(updates)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150)) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
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

enum Relations {
    static let graphTest = Relation(
        primaryChildPath: \.single,
        otherChildren: [RelationKeyPath(\.single), RelationKeyPath(\.children)],
        reduce: { GraphTest(single: $0.single, children: $0.children) }
    )
}
