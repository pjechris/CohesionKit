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

    func test_assign_keyPathIsArray_propertyIsImmutable_arrayIsChanged() {
        var hello = Hello(collection: [1, 2, 3, 4], singleValue: "")

        withUnsafeMutablePointer(to: &hello) {            
            $0.assign(5, to: \Hello.collection, index: 3)
        }
        
        XCTAssertEqual(hello.collection, [1, 2, 3, 5])
    }

    func test_assign_keyPathIsArray_mutipleAssignments_arrayIsChanged() {
        var hello = Hello(collection: [1, 2, 3, 4], singleValue: "")

        withUnsafeMutablePointer(to: &hello) {
            $0.assign(4, to: \Hello.collection, index: 0)
            $0.assign(3, to: \Hello.collection, index: 0)
            $0.assign(2, to: \Hello.collection, index: 0)
        }

        XCTAssertEqual(hello.collection, [2, 2, 3, 4])
    }

    func test_assign_keyPathIsCustomCollection_colectionIsChanged() {
        var hello = Hello(collection: [], singleValue: "")

        hello.myCollection = ["1", "2"]

        withUnsafeMutablePointer(to: &hello) {
            $0.assign("3", to: \.myCollection, index: 0)
            $0.assign("4", to: \.myCollection, index: 0)
        }

        XCTAssertEqual(hello.myCollection, ["3", "4"])
    }
}

private struct Hello {
    let collection: [Int]
    let singleValue: String
    var myCollection: MyCollection = []
}

struct MyCollection: MutableCollection, Equatable, ExpressibleByArrayLiteral {
    typealias Element = Array<String>.Element
    typealias Index = Array<String>.Index

    var elements: [String] = []

    var startIndex: Index { elements.startIndex }

    var endIndex: Index { elements.endIndex }

    init(arrayLiteral elements: String...) {
        self.elements = elements
    }

    subscript(position: Index) -> Element {
        get { 
            elements[position]
        }
        set(newValue) {
            elements[position] = newValue
        }
    }

    func index(after i: Index) -> Index {
        elements.index(after: i)
    }
}
