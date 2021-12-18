import Combine
import CombineExt

/// An `IdentityMap` coupled to an element type using its `Relation` description.
///
/// This object is generated when using `RegistryIdentityMap`
public struct TiedEntityMap<Element, ID: Hashable> {
    public typealias ElementPublisher = AnyPublisher<Element, Never>
    public typealias ElementArrayPublisher = AnyPublisher<[Element], Never>
    
    private let identityMap: IdentityMap
    private let relation: Relation<Element, ID>
    
    init(identityMap: IdentityMap, relation: Relation<Element, ID>) {
        self.identityMap = identityMap
        self.relation = relation
    }
    
    public func store(_ element: Element, alias: String? = nil, modifiedAt: Stamp = Date().stamp) -> ElementPublisher {
        identityMap.store(element, using: relation, alias: alias, modifiedAt: modifiedAt)
    }
    
    public func store<S: Sequence>(_ sequence: S, modifiedAt: Stamp = Date().stamp)
    -> ElementArrayPublisher where S.Element == Element {
        sequence
            .map { object in identityMap.store(object, using: relation, modifiedAt: modifiedAt) }
            .combineLatest()
    }
    
    public func updateIfPresent(for id: ID, modifiedAt: Stamp = Date().stamp, update: (Element) -> Element) {
        identityMap.updateIfPresent(for: id, using: relation, modifiedAt: modifiedAt, update: update)
    }
    
    public func publisher(for id: ID) -> ElementPublisher {
        identityMap.publisher(using: relation, id: id)
    }
 
    public func get(for id: ID) -> Element? {
        identityMap.get(using: relation, id: id)
    }
}
