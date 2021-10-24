import Foundation
import Combine


/// Framework main class.
/// Store and access publishers referencing objects to have realtime updates on them.
/// Memory is automatically released when objects have no observers
public class IdentityMap {
    typealias TypeKey = String
    
    /// in-memory objects collection
    var storages: [TypeKey:Any] = [:]
    /// allow user to use names to refer to stored objects
    /// example: "current_user" to find the current user
    var aliases: [String:TypeKey] = [:]

    /// Create an identity map with a compare function determining when data should be considered as stale and replaced.
    /// - Parameter isStale: this function is used when calling `update` to determine whether or not received data should
    /// replace the existing one. First parameter is existing data, second one is new one
    public init() {
    
    }
    
    func remove<Model>(for type: Model.Type, id: Any) {
        self[type, id: id] = nil
        self.removeAlias(for: type, id: id)
    }

    /// Access the storage for Model given its type and id
    subscript<Model>(type: Model.Type, id id: Any) -> Storage<Model>? {
        get { storages[key(for: type, id: id)] as? Storage<Model> }
        set { storages[key(for: type, id: id)] = newValue }
    }
    
    subscript<Model>(type: Model.Type, id id: Any, init default: @autoclosure () -> Storage<Model>) -> Storage<Model> {
        guard let storage = storages[key(for: type, id: id)] as? Storage<Model> else {
            let storage = `default`()
            
            storages[key(for: type, id: id)] = storage
            
            return storage
        }
        
        return storage
    }
    
    /// Access the storage through alias
    func storageAliased<Model>(_ alias: String) -> Storage<Model>? {
        aliases[alias].flatMap { storages[$0] } as? Storage<Model>
    }
    
    func registerAlias<Model>(_ alias: String?, for type: Model.Type, id: Any) {
        guard let alias = alias else {
            return
        }

        aliases[alias] = key(for: type, id: id)
    }
    
    private func removeAlias<Model>(for type: Model.Type, id: Any) {
        let typeKey = key(for: type, id: id)
        
        if let alias = aliases.first(where: { $0.value == typeKey }) {
            aliases[alias.key] = nil
        }
    }
    
    private func key<Model>(for type: Model.Type, id: Any) -> String {
        "\(type)-\(id)"
    }
    
    /// Add or update an element in the storage with its new value.
    ///
    /// You usually use this method in conjunction with `publisherIfPresent(for:id:)`
    /// - Returns: a Publisher emitting new values for the element. Object stay in memory as long as someone is using the publisher, otherwise it is realeased from the identity map
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
        let id = element[keyPath: relation.idKeyPath]
        
        let storage = self[Element.self, id: id, init: Storage<Element>(id: id, identityMap: self)]
        
        storage.merge(
            recursiveStore(element, using: relation, modifiedAt: modifiedAt),
            modifiedAt: modifiedAt
        )
        
        registerAlias(alias, for: Element.self, id: id)

        return storage.publisher
    }
    
    /// Add or update multiple elements at once into the storage
    /// - Returns: a Publisher emitting a new value when any element from `sequence` is updated in the identity map
    public func store<S: Sequence, ID: Hashable>(
        _ sequence: S,
        using relation: Relation<S.Element, ID>,
        modifiedAt: Stamp = Date().stamp
    ) -> AnyPublisher<[S.Element], Never> {
        sequence
            .map { object in store(object, using: relation, modifiedAt: modifiedAt) }
            .combineLatest()
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
    }
    
    /// Return a publisher emitting event when receiving for the object affiliated to `alias` or nil
    /// if no object with given alias was found
    public func publisher<Element>(for element: Element.Type, aliased alias: String) -> AnyPublisher<Element, Never>? {
        storageAliased(alias)?.publisher
    }

    /// Return element with matching `id` if an object with such `id` was previously inserted
    public func get<Element, ID: Hashable>(
        using relation: Relation<Element, ID>,
        id: ID
    ) -> Element? {
        self[Element.self, id: id]?.value
    }
    
    public func get<Element>(for element: Element.Type, aliased alias: String) -> Element? {
        storageAliased(alias)?.value
    }
    
    private func recursiveStore<Element, ID: Hashable>(
        _ element: Element,
        using relation: Relation<Element, ID>,
        modifiedAt: Stamp = Date().stamp
    ) -> AnyPublisher<Element, Never> {
        guard !relation.allChildren.isEmpty else {
            return Just(element).eraseToAnyPublisher()
        }
        
        return relation
            .allChildren
            .map { identityPath in
                identityPath
                    .store(element, self, modifiedAt)
                    .map { (identityPath.keyPath, $0) }
            }
            .combineLatest()
            // aggregate updates if multiple children are updated in short time
            .debounce(for: 0.1, scheduler: DispatchQueue.global(qos: .utility))
            .map { relation.reduce(Updated(root: element, updates: Dictionary(uniqueKeysWithValues: $0))) }
            .prepend(element)
            .eraseToAnyPublisher()
    }
}
