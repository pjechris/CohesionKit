import Foundation

/// Main class
/// An `IdentityMap` wrapper generating simpler and more typed API
public struct Registry {
    private let identityMap: IdentityMap
    
    /// - Parameter identityMap: the storage used by the registry to handle the data
    public init(identityMap: IdentityMap) {
        self.identityMap = identityMap
    }
    
    /// Give access to the data for the underlying relation type
    ///
    public func storage<Element, ID: Hashable>(for relation: Relation<Element, ID>) -> RegisteredIdentityMap<Element, ID> {
        RegisteredIdentityMap(identityMap: identityMap, tiedTo: relation)
    }
    
    public func storage<Element: Identifiable>(for element: Element.Type) -> RegisteredIdentityMap<Element, Element.ID> {
        RegisteredIdentityMap(identityMap: identityMap, tiedTo: .single())
    }
}
