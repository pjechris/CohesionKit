import Combine
import XCTest
@testable import CohesionKit

class EntityObserverPublisherTests: XCTestCase {
    var cancellables: Set<AnyCancellable> = []
    
    override func setUp() {
        cancellables = []
    }
    
    func test_publisher_valueChange_receiveUpdate() {
        let node = EntityNode(SingleNodeFixture(id: 1), modifiedAt: 0)
        let expected = SingleNodeFixture(id: 1, primitive: "hello")
        let observer = EntityObserver(node: node)
        let expectation = XCTestExpectation()
        
        observer.publisher
            .dropFirst()
            .sink(receiveValue: {
                expectation.fulfill()
                XCTAssertEqual($0, expected)
            })
            .store(in: &cancellables)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            node.updateEntity(expected, modifiedAt: 1)
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func test_publisher_streamIsCancelled_valueChange_receiveNothing() {
        let node = EntityNode(SingleNodeFixture(id: 1), modifiedAt: 0)
        let observer = EntityObserver(node: node)
        let expectation = XCTestExpectation()
        
        expectation.isInverted = true
        
        observer.publisher
            .dropFirst()
            .sink(receiveValue: { _ in expectation.fulfill() })
            .store(in: &cancellables)
        
        cancellables.removeAll()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            node.updateEntity(SingleNodeFixture(id: 1, primitive: "hello"), modifiedAt: 1)
        }
        
        wait(for: [expectation], timeout: 1)
    }

}
