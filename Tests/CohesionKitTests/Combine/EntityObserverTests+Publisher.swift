import Combine
import XCTest

@testable import CohesionKit

class EntityObserverPublisherTests: XCTestCase {
  var cancellables: Set<AnyCancellable> = []

  override func setUp() {
    cancellables = []
  }

  /// make sure publisher signal does not over trigger
  func test_asPublisher_itSinksOnce() {
    let node = EntityNode(SingleNodeFixture(id: 1), modifiedAt: 0)
    let registry = ObserverRegistry(queue: .main)
    let observer = EntityObserver(node: node, registry: registry)
    var sinkCount = 0

    observer
      .asPublisher
      .sink(receiveValue: { _ in sinkCount += 1 })
      .store(in: &cancellables)

    XCTAssertEqual(sinkCount, 1)
  }

  func test_asPublisher_registryPostChangesAfterDelay_itSinks() {
    let expected = SingleNodeFixture(id: 1, primitive: "expected")
    let node = EntityNode(SingleNodeFixture(id: 1, primitive: "init"), modifiedAt: 0)
    let registry = ObserverRegistry(queue: .main)
    let observer = EntityObserver(node: node, registry: registry)
    let expectation = XCTestExpectation()

    observer
      .asPublisher
      .dropFirst()
      .sink(receiveValue: {
        expectation.fulfill()
        XCTAssertEqual($0, expected)
      })
      .store(in: &cancellables)

    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
      try? node.updateEntity(expected, modifiedAt: nil)
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
