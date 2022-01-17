import XCTest
@testable import CohesionKit
import Combine

class IdentityMapRelationalTests: XCTestCase {
    var cancellables: Set<AnyCancellable> = []
    
    override func tearDown() {
        cancellables = []
    }
    
    func test_update_graphObjectIsStored() {
        let expectation = XCTestExpectation()
        let identityMap = IdentityMap()
        let graph = GraphTest(
            single: .init(id: 1, value: "single node"),
            children: [.init(id: 1, key: "child 1")]
        )

        identityMap
            .store(graph, using: Relations.graphTest)
            .sink(receiveValue: { _ in
                XCTAssertEqual(identityMap.get(using: Relations.graphTest, id: 1), graph)
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    func test_store_whenChildIsUpdated_graphObjectIsUpdated() {
        let expectation = XCTestExpectation(description: "wait for updates")
        let identityMap = IdentityMap()
        let graph = GraphTest(
            single: .init(id: 1, value: "single node"),
            children: [.init(id: 1, key: "child 1")]
        )
        let childUpdate = GraphSingleChild(id: 1, value: "single node updated")

        identityMap
            .store(graph, using: Relations.graphTest)
            .sink(receiveValue: { _ in })
            .store(in: &cancellables)
        
        identityMap
            .store(childUpdate, using: Relation.single(), modifiedAt: Date().advanced(by: 1).stamp)
            .delay(for: 0.1, scheduler: RunLoop.main)
            .sink(receiveValue: { _ in
                XCTAssertEqual(identityMap.get(using: SingleRelation<GraphSingleChild>(), id: 1), childUpdate)
                XCTAssertEqual(identityMap.get(using: Relations.graphTest, id: 1)?.single, childUpdate)
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
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
        
        _ = identityMap.store(updates, using: Relation.single())
        
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
        primaryChildPath: \GraphTest.single,
        otherChildren: [RelationKeyPath(\.single), RelationKeyPath(\.children)]
    )
}
