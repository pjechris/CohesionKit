import Foundation

/// An `IdentityMap` wrapper generating simpler and more typed API
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
    public func identityMap<Element, ID: Hashable>(for relation: Relation<Element, ID>) -> RegisteredIdentityMap<Element, ID> {
        RegisteredIdentityMap(identityMap: identityMap, tiedTo: relation)
    }
    
    public func identityMap<Element: Identifiable>(for element: Element.Type) -> RegisteredIdentityMap<Element, Element.ID> {
        RegisteredIdentityMap(identityMap: identityMap, tiedTo: .single())
    }
}
