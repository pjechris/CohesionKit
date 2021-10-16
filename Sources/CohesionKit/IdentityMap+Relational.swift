import Combine
import Foundation

extension IdentityMap {
    /// Add or update an element in the storage with its new value.
    ///
    /// You usually use this method in conjunction with `publisherIfPresent(for:id:)`
    /// - Returns: a Publisher emitting new values for the element. Object stay in memory as long as someone is using the publisher, otherwise it is realeased from the identity map
    /// - Parameter element: the element to add or update
    /// - Parameter relation: Describe the element and how it will be inserted into the identity map.
    /// - Parameter modifiedAt: If value is higher than previous update then the element will be updated. Otherwise changes will be ignored.
    public func store<Element, Identity: Identifiable>(
        _ element: Element,
        relation: Relation<Element, Identity>,
        modifiedAt: Stamp
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
    public func store<S: Sequence, Identity: Identifiable>(
        _ sequence: S,
        relation: Relation<S.Element, Identity>,
        modifiedAt: Stamp
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
    public func storeIfPresent<Element, Identity: Identifiable>(
        _ element: Element,
        relation: Relation<Element, Identity>,
        modifiedAt: Stamp
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
    public func publisher<Element, Identity: Identifiable>(
        for relation: Relation<Element, Identity>,
        id: Identity.ID
    ) -> AnyPublisher<Element, Never> {
        guard let storage = self[Element.self, id: id] else {
            let storage = Storage<Element>(id: id, identityMap: self)

            self[Element.self, id: id] = storage

            return storage.publisher
        }

        return storage.publisher
    }

    /// Return element with matching `id` if an object with such `id` was previously inserted
    public func get<Element, Identity: Identifiable>(
        for relation: Relation<Element, Identity>,
        id: Identity.ID
    ) -> Element? {
        self[Element.self, id: id]?.value
    }
    
    private func recursiveStore<Element, Identity: Identifiable>(
        _ element: Element,
        relation: Relation<Element, Identity>,
        modifiedAt: Stamp)
    -> AnyPublisher<Element, Never> {
        guard !relation.identities.isEmpty else {
            return Just(element).eraseToAnyPublisher()
        }
        
        return relation
            .identities
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
