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
    
    func remove<Model>(for model: Model.Type, id: Any) {
        self[model, id: id] = nil
    }

    /// Access the storage for Model given its type and id
    subscript<Model>(type: Model.Type, id id: Any) -> Storage<Model>? {
        get { map["\(type)"]?[String(describing: id)] as? Storage<Model> }
        set { map["\(type)", default: [:]][String(describing: id)] = newValue }
    }
    
    /// Add or update an element in the storage with its new value.
    ///
    /// You usually use this method in conjunction with `publisherIfPresent(for:id:)`
    /// - Returns: a Publisher emitting new values for the element. Object stay in memory as long as someone is using the publisher, otherwise it is realeased from the identity map
    /// - Parameter element: the element to add or update
    /// - Parameter relation: Describe the element and how it will be inserted into the identity map.
    /// - Parameter modifiedAt: If value is higher than previous update then the element will be updated. Otherwise changes will be ignored.
    public func store<Element, ID: Hashable>(
        _ element: Element,
        relation: Relation<Element, ID>,
        modifiedAt: Stamp = Date().stamp
    ) -> AnyPublisher<Element, Never> {
        let id = element[keyPath: relation.idKeyPath]
        
        guard let publisher = storeIfPresent(element, relation: relation, modifiedAt: modifiedAt) else {
            let storage = Storage<Element>(id: id, identityMap: self)

            self[Element.self, id: id] = storage

            storage.merge(
                recursiveStore(element, relation: relation, modifiedAt: modifiedAt),
                modifiedAt: modifiedAt
            )

            return storage.publisher
        }

        return publisher
    }
    
    /// Add or update multiple elements at once into the storage
    /// - Returns: a Publisher emitting a new value when any element from `sequence` is updated in the identity map
    public func store<S: Sequence, ID: Hashable>(
        _ sequence: S,
        relation: Relation<S.Element, ID>,
        modifiedAt: Stamp = Date().stamp
    ) -> AnyPublisher<[S.Element], Never> {
        sequence
            .map { object in store(object, relation: relation, modifiedAt: modifiedAt) }
            .combineLatest()
    }
    
    /// Update element in the storage only if it's already in it. Otherwise discard the changes.
    ///
    /// You usually use this method in conjunction with `publisher(for:id:)` which will always create a storage for the
    /// element with specified id.
    /// - SeeAlso:
    /// `IdentityMap.store(_,relation:,modifiedAt:)`
    @discardableResult
    public func storeIfPresent<Element, ID: Hashable>(
        _ element: Element,
        relation: Relation<Element, ID>,
        modifiedAt: Stamp = Date().stamp
    ) -> AnyPublisher<Element, Never>? {
        guard let storage = self[Element.self, id: element[keyPath: relation.idKeyPath]] else {
            return nil
        }

        storage.merge(
            recursiveStore(element, relation: relation, modifiedAt: modifiedAt),
            modifiedAt: modifiedAt
        )

        return storage.publisher
    }
    
    /// Return a publisher emitting event when receiving update for `id`.
    /// Note that object might not be present in the storage at the time where publisher is requested.
    /// Thus this publisher *might* never send any value.
    ///
    /// Object stay in memory as long as someone is using the publisher
    public func publisher<Element, ID: Hashable>(
        for relation: Relation<Element, ID>,
        id: ID
    ) -> AnyPublisher<Element, Never> {
        guard let storage = self[Element.self, id: id] else {
            let storage = Storage<Element>(id: id, identityMap: self)

            self[Element.self, id: id] = storage

            return storage.publisher
        }

        return storage.publisher
    }

    /// Return element with matching `id` if an object with such `id` was previously inserted
    public func get<Element, ID: Hashable>(
        for relation: Relation<Element, ID>,
        id: ID
    ) -> Element? {
        self[Element.self, id: id]?.value
    }
    
    private func recursiveStore<Element, ID: Hashable>(
        _ element: Element,
        relation: Relation<Element, ID>,
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
