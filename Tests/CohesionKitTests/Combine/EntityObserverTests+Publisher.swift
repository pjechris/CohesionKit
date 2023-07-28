import Combine
import XCTest
@testable import CohesionKit

class EntityObserverPublisherTests: XCTestCase {
    var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        cancellables = []
    }

    func test_publisher_valueIsPosted_receiveUpdate() {
        let node = EntityNode(SingleNodeFixture(id: 1), modifiedAt: 0)
        let expected = SingleNodeFixture(id: 1, primitive: "hello")
        let registry = ObserverRegistry(queue: .main)
        let observer = EntityObserver(node: node, registry: registry)
        let expectation = XCTestExpectation()

        observer.asPublisher
            .dropFirst()
            .sink(receiveValue: {
                expectation.fulfill()
                XCTAssertEqual($0, expected)
            })
            .store(in: &cancellables)

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            try! node.updateEntity(expected, modifiedAt: nil)

            registry.enqueueNotification(for: node)
            registry.postNotifications()
        }

        wait(for: [expectation], timeout: 1)
    }

    func test_publisher_streamIsCancelled_valueChange_receiveNothing() {
        let node = EntityNode(SingleNodeFixture(id: 1), modifiedAt: 0)
        let registry = ObserverRegistry(queue: .main)
        let observer = EntityObserver(node: node, registry: registry)
        let expectation = XCTestExpectation()

        expectation.isInverted = true

        observer.asPublisher
            .dropFirst()
            .sink(receiveValue: { _ in expectation.fulfill() })
            .store(in: &cancellables)

        cancellables.removeAll()

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            try! node.updateEntity(SingleNodeFixture(id: 1, primitive: "hello"), modifiedAt: 1)
        }

        wait(for: [expectation], timeout: 1)
    }

}
