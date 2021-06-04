import Foundation
import XCTest
import CohesionKit
import Combine

class IdentityMapTests: XCTestCase {

    func test_getForId_entityWasAdded_itReturnEntity() {
        let map = IdentityMap<Date>()

        _ = map.update(Entity.hello)

        XCTAssertNotNil(map.get(for: Entity.self, id: Entity.hello.id))
    }

    func test_getForId_entityWasAdded_allPublishersWereUnsubscribed_entityIsNotStored() {
        let map = IdentityMap<Date>()
        var cancellables: Set<AnyCancellable> = []

        map.update(Entity.hello)
            .sink(receiveValue: { _ in })
            .store(in: &cancellables)

        cancellables.removeAll()

        XCTAssertNil(map.get(for: Entity.self, id: Entity.hello.id))
    }

    func test_updateIfPresent_valueIsNotPresent_itReturnNil() {
        let map = IdentityMap<Date>()

        XCTAssertNil(map.updateIfPresent(Entity.hello))
    }

    func test_publisherForId_entityIsAddedAfterRequestingPublisher_entityIsEmitted() {
        let map = IdentityMap<Date>()
        let publisher = map.publisher(for: Entity.self, id: Entity.hello.id)
        var receivedValue: Entity?
        var cancellables: Set<AnyCancellable> = []

        _ = map.update(Entity.hello)

        publisher
            .sink(receiveValue: { receivedValue = $0 })
            .store(in: &cancellables)

        XCTAssertEqual(receivedValue, Entity.hello)
    }

}

private struct Entity: Identifiable, Equatable {
    let id: Int
    let value: String

    static let hello = Entity(id: 1, value: "hello")
}
