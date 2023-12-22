#if canImport(Combine)
import Combine
import Foundation

extension Publisher {
  /// Stores the `Identifiable` upstream into an entityStore
  public func store(in entityStore: EntityStore, named: AliasKey<Output>? = nil, modifiedAt: Stamp = Date().stamp)
  -> AnyPublisher<Output, Failure> where Output: Identifiable {
    map { entityStore.store(entity: $0, named: named, modifiedAt: modifiedAt).asPublisher }
      .switchToLatest()
      .eraseToAnyPublisher()
  }

  /// Stores the `Aggregate` upstream into an entityStore
  public func store(in entityStore: EntityStore, named: AliasKey<Output>? = nil, modifiedAt: Stamp = Date().stamp)
  -> AnyPublisher<Output, Failure> where Output: Aggregate {
    map { entityStore.store(entity: $0, named: named, modifiedAt: modifiedAt).asPublisher }
      .switchToLatest()
      .eraseToAnyPublisher()
  }

  /// Stores the upstream collection into an entityStore
  public func store(in entityStore: EntityStore, named: AliasKey<Output>? = nil, modifiedAt: Stamp = Date().stamp)
  -> AnyPublisher<[Output.Element], Failure> where Output: Collection, Output.Element: Identifiable {
    map { entityStore.store(entities: $0, named: named, modifiedAt: modifiedAt).asPublisher }
      .switchToLatest()
      .eraseToAnyPublisher()
  }

  /// Stores the upstream collection into an entityStore
  public func store(in entityStore: EntityStore, named: AliasKey<Output>? = nil, modifiedAt: Stamp = Date().stamp)
  -> AnyPublisher<[Output.Element], Failure> where Output: Collection, Output.Element: Aggregate {
    map { entityStore.store(entities: $0, named: named, modifiedAt: modifiedAt).asPublisher }
      .switchToLatest()
      .eraseToAnyPublisher()
  }
}

#endif
