import Combine
import Foundation

extension IdentityMap {
    public func update<Model: IdentityGraph>(_ object: Model, modifiedAt: ModificationStamp = Date().timeIntervalSinceReferenceDate) -> AnyPublisher<Model, Never> {
        guard let publisher = updateIfPresent(object, modifiedAt: modifiedAt) else {
            let storage = Storage<Model>(id: object.idValue, identityMap: self)

            self[object] = storage

            storage.forward(object.update(in: self, modifiedAt: modifiedAt), modifiedAt: modifiedAt)

            return storage.publisher
        }

        return publisher
    }

    public func update<S: Sequence>(_ sequence: S, modifiedAt: ModificationStamp = Date().timeIntervalSinceReferenceDate) -> AnyPublisher<[S.Element], Never> where S.Element: IdentityGraph {
        sequence
            .map { object in update(object, modifiedAt: modifiedAt) }
            .combineLatest()
    }

    @discardableResult
    public func updateIfPresent<Model: IdentityGraph>(_ object: Model, modifiedAt: ModificationStamp = Date().timeIntervalSinceReferenceDate) -> AnyPublisher<Model, Never>? {
        guard let storage = self[object] else {
            return nil
        }

        storage.forward(object.update(in: self, modifiedAt: modifiedAt), modifiedAt: modifiedAt)

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
