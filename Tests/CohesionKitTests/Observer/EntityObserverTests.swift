import XCTest
@testable import CohesionKit

class EntityObserverTests: XCTestCase {
    func test_entityIsUpdated_onChangeIsCalled() throws {
        let node = EntityNode(SingleNodeFixture(id: 0), modifiedAt: 0)
        let observer = EntityObserver(node: node, registry: ObserverRegistry(queue: .main))
        let newEntity = SingleNodeFixture(id: 0, primitive: "new entity version")
        let expectation = XCTestExpectation()

        let subscription = observer.observe {
            expectation.fulfill()
            XCTAssertEqual($0, newEntity)
        }

        try withExtendedLifetime(subscription) {
            try node.updateEntity(newEntity, modifiedAt: 1)
            wait(for: [expectation], timeout: 0.5)
        }
    }
}