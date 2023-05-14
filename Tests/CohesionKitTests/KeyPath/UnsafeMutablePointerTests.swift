import XCTest
@testable import CohesionKit

class UnsafeMutablePointerTests: XCTestCase {
    func test_assign_propertyIsImmutable_propertyIsChanged() {
        var hello = Hello(collection: [], singleValue: "hello")

        withUnsafeMutablePointer(to: &hello) {
            $0.assign("world", to: \Hello.singleValue)
        }

        XCTAssertEqual(hello.singleValue, "world")
    }

    func test_assign_keyPathIsCollection_propertyIsImmutable_collectionIsChangedAtIndex() {
        var hello = Hello(collection: [1, 2, 3, 4], singleValue: "")

        withUnsafeMutablePointer(to: &hello) {            
            $0.assign(5, to: \Hello.collection, index: 3)
        }
        
        XCTAssertEqual(hello.collection, [1, 2, 3, 5])
    }

    func test_assign_keyPathIsCollection_mutipleAssignments_colllectionIsChanged() {
        var hello = Hello(collection: [1, 2, 3, 4], singleValue: "")

        withUnsafeMutablePointer(to: &hello) {
            $0.assign(4, to: \Hello.collection, index: 0)
            $0.assign(3, to: \Hello.collection, index: 0)
            $0.assign(2, to: \Hello.collection, index: 0)
        }

        XCTAssertEqual(hello.collection, [2, 2, 3, 4])
    }
}

private struct Hello {
    let collection: [Int]
    let singleValue: String
}
