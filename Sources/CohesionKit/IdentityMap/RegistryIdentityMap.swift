import Foundation

/// An `IdentityMap` coupled to a `Relation` allowing to use identitymap with strong types.
public struct RegistryIdentityMap {
    private let identityMap: IdentityMap
    
    public init(identityMap: IdentityMap) {
        self.identityMap = identityMap
    }
    
    /// Return a `TiedEntityMap` tying a relation to the identity map.
    ///
    /// This entity will provide same methods than IdentityMap but to use only
    /// with provided relation object. This make those methods shorter and easier to understand
    ///
    /// - Returns: a `TiedEntityMap` allowing to use `IdentityMap` but solely with received `Relation` object
    public func identityMap<Element, ID: Hashable>(for relation: Relation<Element, ID>) -> TiedIdentityMap<Element, ID> {
        TiedIdentityMap(identityMap: identityMap, tiedTo: relation)
    }
    
    public func identityMap<Element: Identifiable>(for element: Element.Type) -> TiedIdentityMap<Element, Element.ID> {
        TiedIdentityMap(identityMap: identityMap, tiedTo: .single())
    }
}
