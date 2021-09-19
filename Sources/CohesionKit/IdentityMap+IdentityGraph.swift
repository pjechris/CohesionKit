import Combine
import Foundation

extension IdentityMap {
    public func store<Model: IdentityGraph>(_ object: Model, modifiedAt: Stamp = Date().stamp) -> AnyPublisher<Model, Never> {
        guard let publisher = storeIfPresent(object, modifiedAt: modifiedAt) else {
            let storage = Storage<Model>(id: object.idValue, identityMap: self)

            self[object] = storage

            storage.forward(object.store(in: self, modifiedAt: modifiedAt), modifiedAt: modifiedAt)

            return storage.publisher
        }

        return publisher
    }

    public func store<S: Sequence>(_ sequence: S, modifiedAt: Stamp = Date().stamp) -> AnyPublisher<[S.Element], Never> where S.Element: IdentityGraph {
        sequence
            .map { object in store(object, modifiedAt: modifiedAt) }
            .combineLatest()
    }

    @discardableResult
    public func storeIfPresent<Model: IdentityGraph>(_ object: Model, modifiedAt: Stamp = Date().stamp) -> AnyPublisher<Model, Never>? {
        guard let storage = self[object] else {
            return nil
        }

        storage.forward(object.store(in: self, modifiedAt: modifiedAt), modifiedAt: modifiedAt)

        return storage.publisher
    }

    public func publisher<Model: IdentityGraph>(for model: Model.Type, id: Model.ID) -> AnyPublisher<Model, Never> {
        guard let storage = self[Model.self, id] else {
            let storage = Storage<Model>(id: id, identityMap: self)

            self[Model.self, id] = storage

            return storage.publisher
        }

        return storage.publisher
    }

    public func get<Model: IdentityGraph>(for model: Model.Type, id: Model.ID) -> Model? {
        self[Model.self, id]?.subject.value?.object
    }

    /// Access the storage for a `IdentityGraph` model
    subscript<Model: IdentityGraph>(model: Model) -> Storage<Model>? {
        get { self[Model.self, model.idValue] }
        set { self[Model.self, model.idValue] = newValue }
    }
}
