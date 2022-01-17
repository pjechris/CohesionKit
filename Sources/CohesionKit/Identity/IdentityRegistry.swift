import Foundation

/// Experimental API
/// An `IdentityMap` wrapper generating simpler and more typed API
public struct IdentityRegistry {
    private let identityMap: IdentityMap
    
    /// - Parameter identityMap: the storage used by the registry to handle the data
    public init(identityMap: IdentityMap) {
        self.identityMap = identityMap
    }
    
    /// Give access to the data for the underlying relation type
    ///
    public func `for`<Element, ID: Hashable>(_ relation: Relation<Element, ID>) -> IdentityMapRelation<Element, ID> {
        IdentityMapRelation(identityMap: identityMap, referring: relation)
    }
    
    public func `for`<Element: Identifiable>(_ element: Element.Type) -> IdentityMapRelation<Element, Element.ID> {
        IdentityMapRelation(identityMap: identityMap, referring: .single())
    }
}
