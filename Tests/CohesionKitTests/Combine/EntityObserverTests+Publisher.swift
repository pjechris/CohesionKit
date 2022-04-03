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
    
    func test_publisherArray_oneValueChange_receiveArrayUpdate() {
        let value1 = SingleNodeFixture(id: 1)
        let value2Modified = SingleNodeFixture(id: 2, primitive: "hello")
        let node2 = EntityNode(SingleNodeFixture(id: 2), modifiedAt: 0)
        let observers = [
            EntityObserver(node: EntityNode(value1, modifiedAt: 0)),
            EntityObserver(node: node2)
        ]
        let expectation = XCTestExpectation()
        
        observers.publisher
            .dropFirst()
            .sink(receiveValue: {
                expectation.fulfill()
                XCTAssertEqual($0, [value1, value2Modified])
            })
            .store(in: &cancellables)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            node2.updateEntity(value2Modified, modifiedAt: 1)
        }
        
        wait(for: [expectation], timeout: 1)
    }
}
