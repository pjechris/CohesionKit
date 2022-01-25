import Combine
import CombineExt

/// An `IdentityMap` coupled to an element type using its `Relation` description.
///
/// This object is generated when using `RegistryIdentityMap`
public struct IdentityStoreRelation<Element, ID: Hashable> {
    public typealias ElementPublisher = AnyPublisher<Element, Never>
    public typealias ArrayPublisher = AnyPublisher<[Element], Never>
    
    private let identityStore: IdentityStore
    private let relation: Relation<Element, ID>
    
    init(identityStore: IdentityStore, referring relation: Relation<Element, ID>) {
        self.identityStore = identityStore
        self.relation = relation
    }
    
    public func store(_ element: Element, alias: String? = nil, modifiedAt: Stamp = Date().stamp) -> ElementPublisher {
      identityStore
        .store(element, using: relation, alias: alias, modifiedAt: modifiedAt)
        .map(\.object)
        .eraseToAnyPublisher()
    }
    
    public func store<S: Sequence>(_ sequence: S, modifiedAt: Stamp = Date().stamp)
    -> ArrayPublisher where S.Element == Element {
      identityStore
        .store(sequence, using: relation, modifiedAt: modifiedAt)
        .map(\.object)
        .eraseToAnyPublisher()
    }

    @discardableResult
    public func storeIfPresent(_ element: Element, alias: String? = nil, modifiedAt: Stamp = Date().stamp)
    -> ElementPublisher? {
      identityStore
          .storeIfPresent(element, using: relation, alias: alias, modifiedAt: modifiedAt)
          .map { $0.map(\.object).eraseToAnyPublisher() }
    }

    public func publisher(for id: ID) -> ElementPublisher {
      identityStore
          .publisher(using: relation, id: id)
          .map(\.object)
          .eraseToAnyPublisher()
    }
    
    public func publisher(aliased alias: String) -> AnyPublisher<Element, Never> {
      identityStore
        .publisher(for: Element.self, aliased: alias)
        .map(\.object)
        .eraseToAnyPublisher()
    }
 
    public func get(for id: ID) -> Element? {
      identityStore.get(using: relation, id: id)
    }
    
    public func get(aliased alias: String) -> Element? {
      identityStore.get(for: Element.self, aliased: alias)
    }
}
