import Foundation

/// An `IdentityMap` wrapper generating simpler and more typed API
public struct IdentityRegistry {
    private let identityStore: IdentityStore
    
    /// - Parameter identityStore: the storage used by the registry to handle the data
    public init(identityStore: IdentityStore) {
        self.identityStore = identityStore
    }
    
    /// Give access to the data for the underlying relation type
    ///
    public func `for`<Element, ID: Hashable>(_ relation: Relation<Element, ID>) -> IdentityStoreRelation<Element, ID> {
        IdentityStoreRelation(identityStore: identityStore, referring: relation)
    }
    
    public func `for`<Element: Identifiable>(_ element: Element.Type) -> IdentityStoreRelation<Element, Element.ID> {
        IdentityStoreRelation(identityStore: identityStore, referring: .single())
    }
}
