import Combine
import Foundation

extension IdentityMap {
    public func store<Element, Identity: Identifiable>(
        _ element: Element,
        relation: Relation<Element, Identity>,
        modifiedAt: Stamp
    ) -> AnyPublisher<Element, Never> {
        let id = element[keyPath: relation.idKeyPath]
        
        guard let publisher = storeIfPresent(element, relation: relation, modifiedAt: modifiedAt) else {
            let storage = Storage<Element>(id: id, identityMap: self)

            self[Element.self, id: id] = storage

            storage.forward(recursiveStore(element, relation: relation, modifiedAt: modifiedAt), modifiedAt: modifiedAt)

            return storage.publisher
        }

        return publisher
    }
    
    public func store<S: Sequence, Identity: Identifiable>(
        _ sequence: S,
        relation: Relation<S.Element, Identity>,
        modifiedAt: Stamp
    ) -> AnyPublisher<[S.Element], Never> {
        sequence
            .map { object in store(object, relation: relation, modifiedAt: modifiedAt) }
            .combineLatest()
    }
    
    @discardableResult
    public func storeIfPresent<Element, Identity: Identifiable>(
        _ element: Element,
        relation: Relation<Element, Identity>,
        modifiedAt: Stamp
    ) -> AnyPublisher<Element, Never>? {
        guard let storage = self[Element.self, id: element[keyPath: relation.idKeyPath]] else {
            return nil
        }

        storage.send(element, modifiedAt: modifiedAt)

        return storage.publisher
    }
    
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

    public func get<Element, Identity: Identifiable>(
        for relation: Relation<Element, Identity>,
        id: Identity.ID
    ) -> Element? {
        self[Element.self, id: id]?.subject.value?.object
    }
    
    func recursiveStore<Element, Identity: Identifiable>(_ element: Element, relation: Relation<Element, Identity>, modifiedAt: Stamp) -> AnyPublisher<Element, Never> {
        relation
            .identities
            .map { identityPath in
                identityPath
                    .update(element, self, modifiedAt)
                    .map { (identityPath.keyPath, $0) }
            }
            .combineLatest()
            // aggregate updates if multiple children are updated in short time
            .debounce(for: 0.1, scheduler: DispatchQueue.global(qos: .utility))
            .map { relation.reduce(KeyPathUpdates(values: Dictionary(uniqueKeysWithValues: $0))) }
            .prepend(element)
            .eraseToAnyPublisher()
    }
    
    /// Access the storage for a `IdentityGraph` model
    subscript<Element, ID: Identifiable>(element: Element, idKeyPath id: KeyPath<Element, ID>) -> Storage<Element>? {
        get { self[Element.self, id: element[keyPath: id].id] }
        set { self[Element.self, id: element[keyPath: id].id] = newValue }
    }
}
