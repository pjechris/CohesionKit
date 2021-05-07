import Combine

public class IdentityMap {
    private var map:[String:Any] = [:]
    
    public init() {
        
    }
    
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
    
    public func get<Model: Identifiable>(_ model: Model.Type, byId id: Model.ID) -> Model? {
        self[Model.self, id]?.subject.value
    }
    
    public func publisher<Model: Identifiable>(_ model: Model.Type, id: Model.ID) -> AnyPublisher<Model, Never>? {
        self[Model.self, id]?.publisher
    }
    
    public func remove<Model: Identifiable>(_ object: Model) {
        print("removing \(Model.self)_\(object.id)")
        self.map.removeValue(forKey: "\(Model.self)_\(object.id)")
    }
    
    subscript<Model: Identifiable>(type: Model.Type, id: Model.ID) -> Storage<Model>? {
        get { map["\(type)_\(id)"] as? Storage<Model> }
        set { map["\(type)_\(id)"] = newValue }
    }
    
    subscript<Model: Identifiable>(model: Model) -> Storage<Model>? {
        get { self[Model.self, model.id] }
        set { self[Model.self, model.id] = newValue }
    }

}

