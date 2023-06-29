import XCTest
@testable import CohesionKit

class RefTests: XCTestCase {
    func test_addObserver_valueChange_observerIsCalled() {
        let ref = Observable(value: "hello")
        var receivedValue: String? = nil
        let subscription = ref.addObserver {
            receivedValue = $0
        }

        ref.value = "hello world"

        XCTAssertEqual(receivedValue, "hello world")

        subscription.unsubscribe() // just to avoid warning on non used variable
    }

    func test_addObserver_whenUnsubscribing_valueChange_observerIsNotCalled() {
        let ref = Observable(value: "hello")

        let subscription = ref.addObserver { _ in
            XCTFail("subscription was canceled: should not have been called")
        }

        subscription.unsubscribe()

        ref.value = "hello world"
    }

    func test_addObserver_subscribingIsDealloc_valueChange_observerIsNotCalled() {
        let ref = Observable(value: "hello")

        _ = ref.addObserver { _ in
            XCTFail("subscription was release: should not have been called")
        }

        ref.value = "hello world"
    }
}
