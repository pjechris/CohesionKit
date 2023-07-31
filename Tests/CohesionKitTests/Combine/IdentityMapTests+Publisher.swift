import XCTest
import Combine
@testable import CohesionKit

class IdentityMapPublisherTests: XCTestCase {
    func test_store_asPublisher_itSinksOnce() {
      let identityMap = IdentityMap(queue: .main)
        var cancellables: Set<AnyCancellable> = []
        var sinkCalled = 0
        let expectation = XCTestExpectation()

        identityMap.store(entity: SingleNodeFixture(id: 1))
        .asPublisher
        .sink { _ in sinkCalled += 1 }
        .store(in: &cancellables)

        // we arbitrarely resolve expectation after which every piece of code runned.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
          expectation.fulfill()
          XCTAssertEqual(sinkCalled, 1)
        }

        wait(for: [expectation], timeout: 0.2)
    }
}
