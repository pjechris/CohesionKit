import Combine
import CombineExt

/// An `IdentityMap` coupled to an element type using its `Relation` description.
///
/// This object is generated when using `RegistryIdentityMap`
public struct IdentityMapRelation<Element, ID: Hashable> {
    public typealias ElementPublisher = AnyPublisher<Element, Never>
    public typealias ArrayPublisher = AnyPublisher<[Element], Never>
    
    private let identityMap: IdentityMap
    private let relation: Relation<Element, ID>
    
    init(identityMap: IdentityMap, referring relation: Relation<Element, ID>) {
        self.identityMap = identityMap
        self.relation = relation
    }
    
    public func store(_ element: Element, alias: String? = nil, modifiedAt: Stamp = Date().stamp) -> ElementPublisher {
        identityMap.store(element, using: relation, alias: alias, modifiedAt: modifiedAt)
    }
    
    public func store<S: Sequence>(_ sequence: S, modifiedAt: Stamp = Date().stamp)
    -> ArrayPublisher where S.Element == Element {
        identityMap.store(sequence, using: relation, modifiedAt: modifiedAt)
    }

    @discardableResult
    public func storeIfPresent(_ element: Element, alias: String? = nil, modifiedAt: Stamp = Date().stamp)
    -> ElementPublisher? {
        identityMap.storeIfPresent(element, using: relation, alias: alias, modifiedAt: modifiedAt)
    }

    public func publisher(for id: ID) -> ElementPublisher {
        identityMap.publisher(using: relation, id: id)
    }
    
    public func publisher(aliased alias: String) -> AnyPublisher<Element, Never> {
        identityMap.publisher(for: Element.self, aliased: alias)
    }
 
    public func get(for id: ID) -> Element? {
        identityMap.get(using: relation, id: id)
    }
    
    public func get(aliased alias: String) -> Element? {
        identityMap.get(for: Element.self, aliased: alias)
    }
}
