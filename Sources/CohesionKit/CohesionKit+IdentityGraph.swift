import Combine

extension IdentityMap {
    public func update<Model: IdentityGraph>(_ object: Model, stamp: Stamp) -> AnyPublisher<Model, Never> {
        guard let publisher = updateIfPresent(object, stampedAt: stamp) else {
            let storage = Storage<Model, Stamp>(id: object.idValue, identityMap: self)

            self[object] = storage

            storage.forward(object.update(in: self, stampedAt: stamp), stampedAt: stamp)

            return storage.publisher
        }

        return publisher
    }

    @discardableResult
    public func updateIfPresent<Model: IdentityGraph>(_ object: Model, stampedAt stamp: Stamp) -> AnyPublisher<Model, Never>? {
        guard let storage = self[object] else {
            return nil
        }

        storage.forward(object.update(in: self, stampedAt: stamp), stampedAt: stamp)

        return storage.publisher
    }

    public func publisher<Model: IdentityGraph>(for model: Model.Type, id: Model.ID) -> AnyPublisher<Model, Never> {
        guard let storage = self[Model.self, id] else {
            let storage = Storage<Model, Stamp>(id: id, identityMap: self)

            self[Model.self, id] = storage

            return storage.publisher
        }

        return storage.publisher
    }

    public func get<Model: IdentityGraph>(for model: Model.Type, id: Model.ID) -> Model? {
        self[Model.self, id]?.subject.value?.object
    }

    /// Access the storage for a `IdentityGraph` model
    subscript<Model: IdentityGraph>(model: Model) -> Storage<Model, Stamp>? {
        get { self[Model.self, model.idValue] }
        set { self[Model.self, model.idValue] = newValue }
    }
}
