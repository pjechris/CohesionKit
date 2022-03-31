import XCTest
@testable import CohesionKit

class UnsafeMutableRawPointerTests: XCTestCase {
    func test_assign_keyPathIsCollection_assignNewValueToIndex() {
        var hello = Hello()

        withUnsafeMutablePointer(to: &hello) {
            let pointer = UnsafeMutableRawPointer($0)
            
            pointer.assign(5, to: \Hello.test, index: 3)
        }
        
        XCTAssertEqual(hello.test, [1, 2, 3, 5])
    }
}

private struct Hello {
    var test = [1, 2, 3, 4]
}
