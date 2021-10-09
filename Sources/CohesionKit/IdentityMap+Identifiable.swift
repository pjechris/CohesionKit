import Foundation
import Combine

extension IdentityMap {
    /// Add or update an `Identifiable` element in the storage with its new value.
    public func store<Element: Identifiable>(_ element: Element, modifiedAt: Stamp) -> AnyPublisher<Element, Never> {
        store(element, relation: Relation(), modifiedAt: modifiedAt)
    }
    
    /// Add or update multiple `Identifiable` elements at once into the storage
    public func store<S: Sequence>(_ sequence: S, modifiedAt: Stamp) -> AnyPublisher<[S.Element], Never>
    where S.Element: Identifiable {
        store(sequence, relation: Relation(), modifiedAt: modifiedAt)
    }
    
    /// Update `Identifiable` element in the storage only if it's already in it. Otherwise discard the changes.
    @discardableResult
    public func storeIfPresent<Element: Identifiable>(_ element: Element, modifiedAt: Stamp) -> AnyPublisher<Element, Never>? {
        storeIfPresent(element, relation: Relation(), modifiedAt: modifiedAt)
    }
    
    /// Return a publisher emitting event when receiving update for `id`.
    public func publisher<Element: Identifiable>(for element: Element.Type, id: Element.ID) -> AnyPublisher<Element, Never> {
        publisher(for: Relation(), id: id)
    }
    
    /// Return element with matching `id` if an object with such `id` was previously inserted
    public func get<Element: Identifiable>(for element: Element.Type, id: Element.ID) -> Element? {
        get(for: Relation<Element, Element>(), id: id)
    }
}
