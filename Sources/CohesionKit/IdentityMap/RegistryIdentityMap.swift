import Foundation

/// An `IdentityMap` coupled to an entity allowing to use identitymap with strong typed keypaths.
///
/// You define relations in an object "Registry" which then allow to access identity map through its keypath
@dynamicMemberLookup
public struct RegistryIdentityMap<Registry> {
    private let identityMap: IdentityMap
    private let registry: Registry
    
    public init(registry: Registry, identityMap: IdentityMap = IdentityMap()) {
        self.identityMap = identityMap
        self.registry = registry
    }
    
    /// Return a `TiedEntityMap` tying a relation to the identity map.
    ///
    /// This entity will provide same methods than IdentityMap but to use only
    /// with provided relation object. This make those methods shorter and easier to understand
    ///
    /// - Parameter keyPath: a keypath from `Registry` returning a `Relation` object
    /// - Returns: a `TiedEntityMap` allowing to use `IdentityMap` but solely with received `Relation` object
    public subscript<Element, ID: Hashable>(dynamicMember keyPath: KeyPath<Registry, Relation<Element, ID>>)
    -> TiedEntityMap<Element, ID> {
        TiedEntityMap(identityMap: identityMap, relation: registry[keyPath: keyPath])
    }
}
