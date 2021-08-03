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
    
    /// Add or update an object in the storage with its new value.
    ///
    /// You usually use this method in conjunction with `publisherIfPresent(for:id:)`
    /// - Returns: a Publisher emitting new values for the object. Object is guaranteed to stay in memory as long as someone is using the publisher
    /// - Parameter modifiedAt: If object has a higher modifiedAt value than previous store value then it will be updated with it, otherwise newObject value will be discarded. By default Date time is used to track `newObject` but you can use anything you want (an incremental id for example).
    public func update<Model: Identifiable>(_ newObject: Model, modifiedAt: Stamp = Date().stamp) -> AnyPublisher<Model, Never> {
        guard let publisher = updateIfPresent(newObject, modifiedAt: modifiedAt) else {
            let storage = Storage(object: newObject, modifiedAt: modifiedAt, identityMap: self)

            self[newObject] = storage

            return storage.publisher
        }

        return publisher
    }

    /// Update object in the storage only if it's already in it. Otherwise discard the changes.
    ///
    /// You usually use this method in conjunction with `publisher(for:id:)` which will always create a storage for the
    /// model with specified id.
    /// - SeeAlso:
    /// `IdentityMap.update(_,modifiedAt:)`
    @discardableResult
    public func updateIfPresent<Model: Identifiable>(_ newObject: Model, modifiedAt: Stamp = Date().stamp) -> AnyPublisher<Model, Never>? {
        guard let storage = self[newObject] else {
            return nil
        }

        storage.send(newObject, modifiedAt: modifiedAt)

        return storage.publisher
    }

    /// Return current object value for `id` if an object with such `id` was previously inserted using `update(_:)` method
    public func get<Model: Identifiable>(for model: Model.Type, id: Model.ID) -> Model? {
        self[Model.self, id]?.subject.value?.object
    }

    /// Remove object from storage
    public func remove<Model: Identifiable>(_ object: Model) {
        self[object] = nil
    }

    func remove<Model>(for model: Model.Type, id: Any) {
        self[model, id] = nil
    }

    /// Access the storage for Model given its type and id
    subscript<Model>(type: Model.Type, id: Any) -> Storage<Model>? {
        get { map["\(type)"]?[String(describing: id)] as? Storage<Model> }
        set { map["\(type)", default: [:]][String(describing: id)] = newValue }
    }

    /// Access the storage for a `Identifiable` model
    subscript<Model: Identifiable>(model: Model) -> Storage<Model>? {
        get { self[Model.self, model.id] }
        set { self[Model.self, model.id] = newValue }
    }
}
