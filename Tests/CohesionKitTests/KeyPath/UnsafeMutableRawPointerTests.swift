import XCTest
@testable import CohesionKit

class UnsafeMutableRawPointerTests: XCTestCase {
    func test_assign_propertyIsImmutable_propertyIsChanged() {
        var hello = Hello()

        withUnsafeMutablePointer(to: &hello) {
            let pointer = UnsafeMutableRawPointer($0)
            
            pointer.assign("world", to: \Hello.singleValue)
        }

        XCTAssertEqual(hello.singleValue, "world")
    }

    func test_assign_keyPathIsCollection_propertyIsImmutable_collectionIsChangedAtIndex() {
        var hello = Hello()

        withUnsafeMutablePointer(to: &hello) {
            let pointer = UnsafeMutableRawPointer($0)
            
            pointer.assign(5, to: \Hello.collection, index: 3)
        }
        
        XCTAssertEqual(hello.collection, [1, 2, 3, 5])
    }
}

private struct Hello {
    let collection = [1, 2, 3, 4]
    let singleValue = "hello"
}
