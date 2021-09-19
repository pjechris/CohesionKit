import Combine
import Foundation

extension IdentityMap {
    /// Update object in the storage only if it's already in it. Otherwise discard the changes.
    ///
    /// You usually use this method in conjunction with `publisher(for:id:)` which will always create a storage for the
    /// model with specified id.
    /// - SeeAlso:
    /// `IdentityMap.store(_,modifiedAt:)`
    @discardableResult
    public func storeIfPresent<Model: Identifiable>(_ newObject: Model, modifiedAt: Stamp = Date().stamp) -> AnyPublisher<Model, Never>? {
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
    
    /// Access the storage for a `Identifiable` model
    subscript<Model: Identifiable>(model: Model) -> Storage<Model>? {
        get { self[Model.self, model.id] }
        set { self[Model.self, model.id] = newValue }
    }
}

// MARK: Publishers

extension IdentityMap {
    /// Add or update an object in the storage with its new value.
    ///
    /// You usually use this method in conjunction with `publisherIfPresent(for:id:)`
    /// - Returns: a Publisher emitting new values for the object. Object is guaranteed to stay in memory as long as someone is using the publisher
    /// - Parameter modifiedAt: If object has a higher modifiedAt value than previous store value then it will be updated with it, otherwise newObject value will be discarded. By default Date time is used to track `newObject` but you can use anything you want (an incremental id for example).
    public func store<Model: Identifiable>(_ newObject: Model, modifiedAt: Stamp = Date().stamp) -> AnyPublisher<Model, Never> {
        guard let publisher = storeIfPresent(newObject, modifiedAt: modifiedAt) else {
            let storage = Storage(object: newObject, modifiedAt: modifiedAt, identityMap: self)

            self[newObject] = storage

            return storage.publisher
        }

        return publisher
    }
    
    /// Add or update an object in the storage with its new value and use current date as object stamp
    public func store<S: Sequence>(_ sequence: S, modifiedAt: Stamp = Date().stamp) -> AnyPublisher<[S.Element], Never> where S.Element: Identifiable {
        return sequence
            .map { store($0, modifiedAt: modifiedAt) }
            .combineLatest()
            .eraseToAnyPublisher()
    }

    /// Return a publisher emitting event when receiving update for `id` if an object with such `id` was previously inserted using `update(_:)` method
    public func publisherIfPresent<Model: Identifiable>(for model: Model.Type, id: Model.ID) -> AnyPublisher<Model, Never>? {
        self[Model.self, id]?.publisher
    }

    /// Return a publisher emitting event when receiving update for `id`. Note that object might not be present in the storage
    /// at the time where publisher is requested. Thus this publisher *might* never send any value.
    ///
    /// Object is guaranteed to stay in memory as long as someone is using the publisher
    public func publisher<Model: Identifiable>(for model: Model.Type, id: Model.ID) -> AnyPublisher<Model, Never> {
        guard let storage = self[Model.self, id] else {
            let storage = Storage<Model>(id: id, identityMap: self)

            self[Model.self, id] = storage

            return storage.publisher
        }

        return storage.publisher
    }

    /// Return a publisher emitting event containing latest elements values.
    /// Note that all elements have to emit at least ONCE before this publisher emitting a value.
    /// - Parameters ids: the elements ids
    public func publisher<Element: Identifiable>(for element: [Element].Type, ids: [Element.ID]) -> AnyPublisher<[Element], Never> {
        ids
            .map { publisher(for: Element.self, id: $0) }
            .combineLatest()
    }
}
