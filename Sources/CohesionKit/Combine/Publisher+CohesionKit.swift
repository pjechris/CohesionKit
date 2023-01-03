#if canImport(Combine)
import Combine
import Foundation

extension Publisher {
  /// Stores the `Identifiable` upstream into an identityMap
  public func store(in identityMap: IdentityMap, named: AliasKey<Output>? = nil, modifiedAt: Stamp = Date().stamp)
  -> some Publisher<Output, Failure> where Output: Identifiable {
    map { identityMap.store(entity: $0, named: named, modifiedAt: modifiedAt).asPublisher }
      .switchToLatest()
  }

  /// Stores the `Aggregate` upstream into an identityMap
  public func store(in identityMap: IdentityMap, named: AliasKey<Output>? = nil, modifiedAt: Stamp = Date().stamp)
  -> some Publisher<Output, Failure> where Output: Aggregate {
    map { identityMap.store(entity: $0, named: named, modifiedAt: modifiedAt).asPublisher }
      .switchToLatest()
  }

  /// Stores the upstream collection into an identityMap
  public func store(in identityMap: IdentityMap, named: AliasKey<Output>? = nil, modifiedAt: Stamp = Date().stamp)
  -> some Publisher<[Output.Element], Failure> where Output: Collection, Output.Element: Identifiable {
    map { identityMap.store(entities: $0, named: named, modifiedAt: modifiedAt).asPublisher }
      .switchToLatest()
  }

  /// Stores the upstream collection into an identityMap
  public func store(in identityMap: IdentityMap, named: AliasKey<Output>? = nil, modifiedAt: Stamp = Date().stamp)
  -> some Publisher<[Output.Element], Failure> where Output: Collection, Output.Element: Aggregate {
    map { identityMap.store(entities: $0, named: named, modifiedAt: modifiedAt).asPublisher }
      .switchToLatest()
  }
}

#endif
