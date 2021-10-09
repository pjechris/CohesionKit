import Foundation
import Combine


/// Framework main class.
/// Store and access publishers referencing `Identifiable` objects to have realtime updates on them.
/// Memory is automatically released when objects have no observers
public class IdentityMap {
    var map:[String:[String:Any]] = [:]

    /// Create an identity map with a compare function determining when data should be considered as stale and replaced.
    /// - Parameter isStale: this function is used when calling `update` to determine whether or not received data should
    /// replace the existing one. First parameter is existing data, second one is new one
    public init() {

    }
    
    func remove<Model>(for model: Model.Type, id: Any) {
        self[model, id: id] = nil
    }

    /// Access the storage for Model given its type and id
    subscript<Model>(type: Model.Type, id id: Any) -> Storage<Model>? {
        get { map["\(type)"]?[String(describing: id)] as? Storage<Model> }
        set { map["\(type)", default: [:]][String(describing: id)] = newValue }
    }
}
