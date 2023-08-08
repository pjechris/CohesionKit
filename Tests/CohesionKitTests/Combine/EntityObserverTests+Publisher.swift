import Combine
import XCTest

@testable import CohesionKit

class EntityObserverPublisherTests: XCTestCase {
  var cancellables: Set<AnyCancellable> = []

  override func setUp() {
    cancellables = []
  }

  /// make sure publisher signal does not over trigger
  func test_asPublisher_registryPostChanges_itSinksOnce() {
    let node = EntityNode(SingleNodeFixture(id: 1), modifiedAt: 0)
    let registry = ObserverRegistry(queue: .main)
    let observer = EntityObserver(node: node, registry: registry)
    let expectation = XCTestExpectation()
    var sinkCount = 0

    observer
      .asPublisher
      .sink(receiveValue: { _ in sinkCount += 1 })
      .store(in: &cancellables)

    registry.enqueueChange(for: node)
    registry.postChanges()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      expectation.fulfill()
      XCTAssertEqual(sinkCount, 1)
    }

    wait(for: [expectation], timeout: 0.2)
  }

  func test_asPublisher_registryPostChangesAfterDelay_itSinks() {
    let expected = SingleNodeFixture(id: 1, primitive: "hello")
    let node = EntityNode(expected, modifiedAt: 0)
    let registry = ObserverRegistry(queue: .main)
    let observer = EntityObserver(node: node, registry: registry)
    let expectation = XCTestExpectation()

    observer
      .asPublisher
      .sink(receiveValue: {
        expectation.fulfill()
        XCTAssertEqual($0, expected)
      })
      .store(in: &cancellables)

    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
      registry.enqueueChange(for: node)
      registry.postChanges()
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
