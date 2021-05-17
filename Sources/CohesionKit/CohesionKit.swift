import Combine

/// Main class of the framework.
/// Store references to publishers to `Identifiable` objects so you can easily update and get updates for them.
/// Memory is automatically released when objects are not observed anymore
public class IdentityMap {
    private var map:[String:Any] = [:]
    
    public init() {
        
    }

    /// Update an object in the storage with its new value
    /// - Returns: a Publisher emitting new values for the object.
    @discardableResult
    public func update<Model: Identifiable>(_ object: Model) -> AnyPublisher<Model, Never> {
        guard let storage = self[object] else {
            let storage = Storage(object: object, identityMap: self)

            self[object] = storage
            
            return storage.publisher
        }
        
        storage.subject.send(object)
        
        return storage.publisher
    }

    /// Return current object value for `id` if present in storage
    public func get<Model: Identifiable>(for model: Model.Type, id: Model.ID) -> Model? {
        self[Model.self, id]?.subject.value
    }

    /// Return a publisher emitting event when receiving update for `id` if `id` is already present
    public func publisherIfPresent<Model: Identifiable>(for model: Model.Type, id: Model.ID) -> AnyPublisher<Model, Never>? {
        self[Model.self, id]?.publisher
    }

    /// Return a publisher emitting event when receiving update for `id`. Note that `id` might not be present in the storage
    /// at the time where publisher is requested. Thus this publisher *might* never send any value
    public func publisher<Model: Identifiable>(for model: Model.Type, id: Model.ID) -> AnyPublisher<Model, Never> {
        guard let storage = self[Model.self, id] else {
            let storage = Storage<Model>(id: id, identityMap: self)

            self[Model.self, id] = storage

            return storage.publisher
        }

        return storage.publisher
    }

    /// Remove object from storage
    public func remove<Model: Identifiable>(for object: Model) {
        self[object] = nil
    }

    func remove<Model: Identifiable>(for model: Model.Type, id: Model.ID) {
        self[model, id] = nil
    }
    
    private subscript<Model: Identifiable>(type: Model.Type, id: Model.ID) -> Storage<Model>? {
        get { map["\(type)_\(id)"] as? Storage<Model> }
        set { map["\(type)_\(id)"] = newValue }
    }
    
    private subscript<Model: Identifiable>(model: Model) -> Storage<Model>? {
        get { self[Model.self, model.id] }
        set { self[Model.self, model.id] = newValue }
    }

}

