import XCTest
import Combine
@testable import CohesionKit

class UpdatedTests: XCTestCase {
  
  func test_reduce_rootKeyPathsAreUpdated() {
    let root = Test(scalar: "initial", array: [])
    let updated = Test(scalar: "updated", array: ["nonEmpty"])
    
    XCTAssertEqual(
      Updated(root: root, updates: [\.scalar: updated.scalar, \.array: updated.array]).reduce(),
      updated
    )
  }
  
}

private struct Test: Equatable {
  let scalar: String
  let array: [String]
}
