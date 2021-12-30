import XCTest
import Combine
@testable import CohesionKit

class StorageTests: XCTestCase {
    func test_send_modifiedAtEqualPreviousModification_valueIsNotChanged() {
        let storage = Storage<String> {
            
        }
        let stamp = Date().stamp
        
        storage.send((object: "hello", modifiedAt: stamp))
        storage.send((object: "hello world", modifiedAt: stamp))
        
        XCTAssertEqual(storage.value, "hello")
    }
}
