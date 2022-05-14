import Foundation

/// 
public protocol Logger {
    /// called when an entity was stored in the identity map
    /// - Parameter type: the entity type
    /// - Parameter id: id of the stored entity
    func stored<T: Identifiable>(_ type: T.Type, id: T.ID)
    
    func storeFailed<T: Identifiable>(_ type: T.Type, id: T.ID, error: Error)
    
    /// called when alias is registered to another entity
    func registeredAlias<T>(_ alias: AliasKey<T>)
    
    /// called when alias is manually unregistered
    func unregisteredAlias<T>(_ alias: AliasKey<T>)
}
