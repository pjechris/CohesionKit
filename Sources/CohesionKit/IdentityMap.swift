import Foundation
import Combine

/// Framework main class.
/// Store and access publishers referencing objects to have realtime updates on them.
/// Memory is automatically released when objects have no observers
public class IdentityMap {
    
    /// in-memory storages. Storages are deallocated automatically (unless aliased)
    var values: [String:Any] = [:]
    /// access stored values by names. `aliases` have their own storage and values are forwarded to it. Therefore
    /// when aliased a value won't be released automatically
    /// example: "current_user" to find the current user
    /// - Parameter storage: the alias storage
    /// - Parameter token: token on alias `storage.publisher` the storage alive
    var aliases: [String:(storage: Any, token: AnyCancellable?)] = [:]

    public init() { }
    
    func remove<Model>(for type: Model.Type, id: Any) {
        self[type, id: id] = nil
    }
    
    /// Remove an alias from the identity map.
    /// You should call this method to release any data strongly referenced by `alias`
    public func remove(alias: String) {
        aliases[alias] = nil
    }

    /// Access and set the storage for Model given its type and id
    subscript<Model>(type: Model.Type, id id: Any) -> Storage<Model>? {
        get { values[key(for: type, id: id)] as? Storage<Model> }
        set { values[key(for: type, id: id)] = newValue }
    }
    
    /// Access the storage and initialize it if value is not present
    subscript<Model>(type: Model.Type, id id: Any, init default: @autoclosure () -> Storage<Model>) -> Storage<Model> {
        guard let storage = values[key(for: type, id: id)] as? Storage<Model> else {
            let storage = `default`()
            
            values[key(for: type, id: id)] = storage
            
            return storage
        }
        
        return storage
    }
    
    /// Register a storage under a given alias. Values will be accessible using this alias
    func register<Model>(alias: String?, storage valueStorage: Storage<Model>) {
        guard let key = alias else {
            return
        }
        
        let storage = self.storage(aliased: key) as Storage<Model>
        
        storage.merge(valueStorage.publisher)
        
        aliases[key] = (storage: storage, token: storage.publisher.sink(receiveValue: { _ in }))
    }
    
    /// Find an aliased storage. Be careful: This is storage from `values` but from `aliases`
    func storage<Model>(aliased key: String) -> Storage<Model> {
        if let storage = aliases[key]?.storage as? Storage<Model> {
            return storage
        }
        
        let alias = (storage: Storage<Model> { }, token: AnyCancellable?.none)
        
        aliases[key] = alias
        
        return alias.storage
    }
    
    private func key<Model>(for type: Model.Type, id: Any) -> String {
        "\(type)-\(id)"
    }
    
    /// Add or update an element in the storage with its new value.
    ///
    /// You usually use this method in conjunction with `publisherIfPresent(for:id:)`
    /// - Returns: a Publisher emitting new values for the element. Object stay in memory as long as someone is using the publisher (or if aliased), otherwise it is realeased from the identity map
    /// - Parameter element: the element to add or update
    /// - Parameter relation: Describe the element and how it will be inserted into the identity map.
    /// - Parameter alias: a string key which can be used to find back the element without having its id
    /// - Parameter modifiedAt: If value is higher than previous update then the element will be updated. Otherwise changes will be ignored.
    public func store<Element, ID: Hashable>(
        _ element: Element,
        using relation: Relation<Element, ID>,
        alias: String? = nil,
        modifiedAt: Stamp = Date().stamp
    ) -> AnyPublisher<Element, Never> {
        _store(element, using: relation, alias: alias, modifiedAt: modifiedAt).map(\.object).eraseToAnyPublisher()
    }
    
    public func store<S: Sequence, ID: Hashable>(
        _ sequence: S,
        using relation: Relation<S.Element, ID>,
        modifiedAt: Stamp = Date().stamp
    ) -> AnyPublisher<[S.Element], Never> {
        _store(sequence, using: relation, modifiedAt: modifiedAt).map(\.object).eraseToAnyPublisher()
    }
    
    /// Update element in the storage only if it's already in it. Otherwise discard the changes.
    ///
    /// You usually use this method in conjunction with `publisher(using:id:)` which will always create a storage for the
    /// element with specified id.
    /// - SeeAlso:
    /// `IdentityMap.store(_:relation:alias:modifiedAt:)`
    @discardableResult
    public func storeIfPresent<Element, ID: Hashable>(
        _ element: Element,
        using relation: Relation<Element, ID>,
        alias: String? = nil,
        modifiedAt: Stamp = Date().stamp
    ) -> AnyPublisher<Element, Never>? {
        
        guard self[Element.self, id: element[keyPath: relation.idKeyPath]] != nil else {
            return nil
        }
        
        return store(element, using: relation, alias: alias, modifiedAt: modifiedAt)
    }
    
    /// Return a publisher emitting event when receiving update for `id`.
    /// Note that object might not be present in the storage at the time where publisher is requested.
    /// Thus this publisher *might* never send any value.
    ///
    /// Object stay in memory as long as someone is using the publisher
    public func publisher<Element, ID: Hashable>(
        using relation: Relation<Element, ID>,
        id: ID
    ) -> AnyPublisher<Element, Never> {
        let storage = self[Element.self, id: id, init: Storage<Element>(id: id, identityMap: self)]
        
        return storage.publisher
            .map(\.object).eraseToAnyPublisher()
    }
    
    /// Return a publisher emitting event when receiving update on `alias`
    public func publisher<Element>(for element: Element.Type, aliased alias: String) -> AnyPublisher<Element, Never> {
        storage(aliased: alias).publisher.map(\.object).eraseToAnyPublisher()
    }

    /// Return element with matching `id` if an object with such `id` was previously inserted
    public func get<Element, ID: Hashable>(using relation: Relation<Element, ID>, id: ID) -> Element? {
        self[Element.self, id: id]?.value
    }
    
    /// Return element matching `alias`
    public func get<Element>(for element: Element.Type, aliased alias: String) -> Element? {
        storage(aliased: alias).value
    }
    
    func _store<Element, ID: Hashable>(
        _ element: Element,
        using relation: Relation<Element, ID>,
        alias: String? = nil,
        modifiedAt: Stamp = Date().stamp
    ) -> AnyPublisher<StampedObject<Element>, Never> {
        let id = element[keyPath: relation.idKeyPath]
        let storage = self[Element.self, id: id, init: Storage<Element>(id: id, identityMap: self)]
        
        storage.merge(recursiveStore(element, using: relation, modifiedAt: modifiedAt))
        
        
        register(alias: alias, storage: storage)

        return storage.publisher
    }
    
    /// Add or update multiple elements at once into the storage
    /// - Returns: a Publisher emitting a new value when any element from `sequence` is updated in the identity map
    func _store<S: Sequence, ID: Hashable>(
        _ sequence: S,
        using relation: Relation<S.Element, ID>,
        modifiedAt: Stamp = Date().stamp
    ) -> AnyPublisher<StampedObject<[S.Element]>, Never> {
        sequence
            .map { object in _store(object, using: relation, modifiedAt: modifiedAt) }
            .combineLatest()
            .map { collection in
                collection.reduce((object: [], modifiedAt: 0)) { result, element in
                    (object: result.object + [element.object], modifiedAt: max(result.modifiedAt, element.modifiedAt))
                }
            }
            .eraseToAnyPublisher()
    }
    
    private func recursiveStore<Element, ID: Hashable>(
        _ element: Element,
        using relation: Relation<Element, ID>,
        modifiedAt: Stamp = Date().stamp
    ) -> AnyPublisher<StampedObject<Element>, Never> {
        guard !relation.allChildren.isEmpty else {
            return Just((object: element, modifiedAt: modifiedAt)).eraseToAnyPublisher()
        }

        return relation
            .allChildren
            .map { identityPath in
                identityPath
                    .store(element, self, modifiedAt)
                    .map { (key: identityPath.keyPath, value: $0) }
            }
            .combineLatest()
            // aggregate updates if multiple children are updated in short time
            .debounce(for: 0.1, scheduler: DispatchQueue.global(qos: .utility))
            .map {
                $0.reduce(into: (updates: [:], modifiedAt: 0)) { result, element in
                    result.updates[element.key] = element.value.0
                    result.modifiedAt = max(result.modifiedAt, element.value.1)
                }
            }
            .map {
                (
                    object: relation.reduce(Updated(root: element, updates: $0.updates)),
                    modifiedAt: $0.modifiedAt
                )
            }
            .eraseToAnyPublisher()
    }
}
