import Foundation
import XCTest
@testable import CohesionKit
import Combine

class IdentityStoreTests: XCTestCase {

  func test_getForId_entityWasAdded_itReturnEntity() {
    let map = IdentityMap()

    _ = map.store(Entity.hello, using: Relation.single(), modifiedAt: Date().stamp)

    XCTAssertNotNil(map.get(using: SingleRelation<Entity>(), id: Entity.hello.id))
  }

  func test_getForId_valueIsAdded_valueIsCancelled_itReturnNil() {
    let map = IdentityMap()
    var cancellables: Set<AnyCancellable> = []

    map.store(Entity.hello, using: Relation.single(), modifiedAt: Date().stamp)
      .sink(receiveValue: { _ in })
      .store(in: &cancellables)

    cancellables.removeAll()

    XCTAssertNil(map.get(using: SingleRelation<Entity>(), id: Entity.hello.id))
  }

  func test_storeIfPresent_valueIsNotPresent_itReturnNil() {
    let map = IdentityMap()

    XCTAssertNil(map.storeIfPresent(Entity.hello, using: Relation.single(), modifiedAt: Date().stamp))
  }

  func test_publisherForId_entityIsAddedAfterRequesting_entityIsEmitted() {
    let map = IdentityMap()
    let publisher = map.publisher(using: SingleRelation<Entity>(), id: Entity.hello.id)
    var receivedValue: StampedObject<Entity>?
    var cancellables: Set<AnyCancellable> = []

    _ = map.store(Entity.hello, using: Relation.single(), modifiedAt: Date().stamp)

    publisher
      .sink(receiveValue: { receivedValue = $0 })
      .store(in: &cancellables)

    XCTAssertEqual(receivedValue?.object, Entity.hello)
  }
    
  func test_getAliased_valueWasStoreWithAlias_itRetunValue() {
    let map = IdentityMap()
    var cancellables: Set<AnyCancellable> = []

    map.store(Entity.hello, using: SingleRelation<Entity>(), alias: "test_alias")
      .sink(receiveValue: { _ in })
      .store(in: &cancellables)

    XCTAssertNotNil(map.get(for: Entity.self, aliased: "test_alias"))
  }
    
  func test_getAliased_valueIsCancelled_itReturnValue() {
    let map = IdentityMap()
    var cancellables: Set<AnyCancellable> = []

    map.store(Entity.hello, using: SingleRelation<Entity>(), alias: "test_alias")
      .sink(receiveValue: { _ in })
      .store(in: &cancellables)

    cancellables.removeAll()

    XCTAssertNotNil(map.get(for: Entity.self, aliased: "test_alias"))
  }

  func test_getAliased_valueIsCancelled_aliasIsRemoved_itReturnNil() {
    let map = IdentityMap()
    var cancellables: Set<AnyCancellable> = []

    map.store(Entity.hello, using: SingleRelation<Entity>(), alias: "test_alias")
      .sink(receiveValue: { _ in })
      .store(in: &cancellables)

    cancellables.removeAll()

    map.remove(alias: "test_alias")

    XCTAssertNil(map.get(for: Entity.self, aliased: "test_alias"))
  }
}

private struct Entity: Identifiable, Equatable {
    let id: Int
    let value: String

    static let hello = Entity(id: 1, value: "hello")
}
