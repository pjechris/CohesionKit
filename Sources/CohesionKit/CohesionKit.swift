import Foundation
import Combine

/// Framework main class.
/// Store and access publishers referencing `Identifiable` objects to have realtime updates on them.
/// Memory is automatically released when objects have no observers
public class IdentityMap<Stamp: Comparable> {
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
    /// - Parameter stamp: a value to determine if object should replace existing one or be discarded. This is useful in realtime services where you might sometimes receive a message with some delay that should be ignored becaused more recent data has already been stored.
    public func update<Model: Identifiable>(_ newObject: Model, stamp objectStamp: Stamp) -> AnyPublisher<Model, Never> {
        guard let publisher = updateIfPresent(newObject, stamp: objectStamp) else {
            let storage = Storage(object: newObject, stamp: objectStamp, identityMap: self)

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
    /// `IdentityMap.update(_,stamp:)`
    @discardableResult
    public func updateIfPresent<Model: Identifiable>(_ newObject: Model, stamp objectStamp: Stamp) -> AnyPublisher<Model, Never>? {
        guard let storage = self[newObject] else {
            return nil
        }

        storage.send(newObject, stamp: objectStamp)

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
    subscript<Model>(type: Model.Type, id: Any) -> Storage<Model, Stamp>? {
        get { map["\(type)"]?[String(describing: id)] as? Storage<Model, Stamp> }
        set { map["\(type)", default: [:]][String(describing: id)] = newValue }
    }

    /// Access the storage for a `Identifiable` model
    subscript<Model: Identifiable>(model: Model) -> Storage<Model, Stamp>? {
        get { self[Model.self, model.id] }
        set { self[Model.self, model.id] = newValue }
    }
}

// MARK: Date stamp extension

extension IdentityMap {
    /// Add or update an object in the storage with its new value and use current date as object stamp
    public func update<Model: Identifiable>(_ newObject: Model) -> AnyPublisher<Model, Never> where Stamp == Date {
        self.update(newObject, stamp: Date())
    }

    /// Update object in the storage if it's already in it and use current date as object stamp
    @discardableResult
    public func updateIfPresent<Model: Identifiable>(_ newObject: Model) -> AnyPublisher<Model, Never>? where Stamp == Date {
        self.updateIfPresent(newObject, stamp: Date())
    }
}

extension IdentityMap: AnyIdentityMap {
    func update<Model: Identifiable>(_ newObject: Model, stamp: Any) -> AnyPublisher<Model, Never> {
        guard let stamp = stamp as? Stamp else {
            return publisher(for: Model.self, id: newObject.id)
        }

        return update(newObject, stamp: stamp)
    }

    func update<Model: IdentityGraph>(_ object: Model, stamp: Any) -> AnyPublisher<Model, Never> {
        return update(object, stamp: stamp as! Stamp)
    }

    func update<Model: IdentityGraph>(_ object: [Model], stamp: Any) -> AnyPublisher<[Model], Never> {
        guard let stamp = stamp as? Stamp else {
            return object
                .map(\.idValue)
                .map { publisher(for: Model.self, id: $0) }
                .combineLatest()
                .eraseToAnyPublisher()
        }

        return update(object, stamp: stamp)
    }
}
