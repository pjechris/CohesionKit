import Foundation

/// a protocol reporting `IdentityMap` internal information
public protocol Logger {
    /// Notify when an entity was stored in the identity map
    /// - Parameter type: the entity type
    /// - Parameter id: id of the stored entity
    func didStore<T: Identifiable>(_ type: T.Type, id: T.ID)
    
    func didFailedToStore<T: Identifiable>(_ type: T.Type, id: T.ID, error: Error)
    
    /// Notify an alias is registered with new entities
    func didRegisterAlias<T>(_ alias: AliasKey<T>)
    
    /// Notify an alias is suppressed from the identity map
    func didUnregisterAlias<T>(_ alias: AliasKey<T>)
}
