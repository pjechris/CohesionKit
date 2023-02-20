import Foundation

/// Manages entities lifecycle and synchronisation
public class IdentityMap {
    public typealias Update<T> = (inout T) -> Void

    private(set) var storage: WeakStorage = WeakStorage()
    private(set) var refAliases: AliasStorage = [:]
    private lazy var storeVisitor = IdentityMapStoreVisitor(identityMap: self)
    /// the queue on which identity map do its heavy work
    private let identityQueue = DispatchQueue(label: "com.cohesionkit.identitymap", attributes: .concurrent)
    /// dispatch queue to return the results
    private let observeQueue: DispatchQueue
    private let logger: Logger?

    /// Create a new IdentityMap instance optionally with a queue and a logger
    /// - Parameter queue: the queue on which to receive updates. If not defined it default to main
    /// - Parameter logger: a logger to follow/debug identity internal state
    public init(queue: DispatchQueue = .main, logger: Logger? = nil) {
        self.logger = logger
        self.observeQueue = queue
    }

    /// Store an entity in the storage. Entity will be stored only if stamp (`modifiedAt`) is higher than in previous
    /// insertion.
    /// - Parameter entity: the element to store in the identity map
    /// - Parameter named: an alias to reference the entity and retrieve it using it
    /// - Parameter modifiedAt: if entity was already stored it will be used to determine if the  update should be  applied or discarded
    /// - Returns: an object to observe changes on the entity
    public func store<T: Identifiable>(entity: T, named: AliasKey<T>? = nil, modifiedAt: Stamp = Date().stamp)
    -> EntityObserver<T> {
        identityQueue.sync(flags: .barrier) {
            let node = nodeStore(entity: entity, modifiedAt: modifiedAt)

            if let alias = named {
                refAliases.insert(node, key: alias)
                logger?.didRegisterAlias(alias)
            }

            return EntityObserver(node: node, queue: observeQueue)
        }
    }

    /// Store an aggregate in the storage. Each aggregate entities will be stored only if stamp (`modifiedAt`) is higher than in previous
    /// insertion. Finally aggregate will be stored accordingly to each of its entities.
    /// - Parameter entity: the aggregate to store in the identity map
    /// - Parameter named: an alias to reference the aggregate and retrieve it using it
    /// - Parameter modifiedAt: if aggregate was already stored it will be used to determine if the  update should be  applied or discarded
    /// - Returns: an object to observe changes on the entity
    public func store<T: Aggregate>(entity: T, named: AliasKey<T>? = nil, modifiedAt: Stamp = Date().stamp)
    -> EntityObserver<T> {
        identityQueue.sync(flags: .barrier) {
            let node = nodeStore(entity: entity, modifiedAt: modifiedAt)

            if let alias = named {
                refAliases.insert(node, key: alias)
                logger?.didRegisterAlias(alias)
            }

            return EntityObserver(node: node, queue: observeQueue)
        }
    }

    /// Store multiple entities at once
    public func store<C: Collection>(entities: C, named: AliasKey<C>? = nil, modifiedAt: Stamp = Date().stamp)
    -> [EntityObserver<C.Element>] where C.Element: Identifiable {
        identityQueue.sync(flags: .barrier) {
            let nodes = entities.map { nodeStore(entity: $0, modifiedAt: modifiedAt) }

            if let alias = named {
                refAliases.insert(nodes, key: alias)
                logger?.didRegisterAlias(alias)
            }

            return nodes.map { EntityObserver(node: $0, queue: observeQueue) }
        }
    }

    /// store multiple aggregates at once
    public func store<C: Collection>(entities: C, named: AliasKey<C>? = nil, modifiedAt: Stamp = Date().stamp)
    -> [EntityObserver<C.Element>] where C.Element: Aggregate {
        identityQueue.sync(flags: .barrier) {
            let nodes = entities.map { nodeStore(entity: $0, modifiedAt: modifiedAt) }

            if let alias = named {
                refAliases.insert(nodes, key: alias)
                logger?.didRegisterAlias(alias)
            }

            return nodes.map { EntityObserver(node: $0, queue: observeQueue) }
        }
    }

    /// Try to find an entity/aggregate in the storage.
    /// - Returns: nil if not found, an `EntityObserver`` otherwise
    /// - Parameter type: the entity type
    /// - Parameter id: the entity id
    public func find<T: Identifiable>(_ type: T.Type, id: T.ID) -> EntityObserver<T>? {
        identityQueue.sync {
            if let node = storage[EntityNode<T>.self, id: id] {
                return EntityObserver(node: node, queue: observeQueue)
            }

            return nil
        }
    }

    /// Try to find an entity/aggregate registered under `named` alias
    /// - Parameter named: the alias to look for
    public func find<T: Identifiable>(named: AliasKey<T>) -> AliasObserver<T> {
        identityQueue.sync {
            AliasObserver(alias: refAliases[named], queue: observeQueue)
        }
    }

    /// Try to find a collected registered under `named` alias
    /// - Returns: an observer returning the alias value. Note that the value will be an Array
    public func find<C: Collection>(named: AliasKey<C>) -> AliasObserver<[C.Element]> {
        identityQueue.sync {
            AliasObserver(alias: refAliases[named], queue: observeQueue)
        }
    }

    /// Remove an alias from the storage
    public func removeAlias<T>(named: AliasKey<T>) {
        refAliases.remove(for: named)
        logger?.didUnregisterAlias(named)
    }

    /// Remove an alias from the storage
    public func removeAlias<C: Collection>(named: AliasKey<C>) {
        refAliases.remove(for: named)
        logger?.didUnregisterAlias(named)
    }

    func nodeStore<T: Identifiable>(entity: T, modifiedAt: Stamp) -> EntityNode<T> {
        let node = storage[entity, new: EntityNode(entity, modifiedAt: nil)]

        do {
            try node.updateEntity(entity, modifiedAt: modifiedAt)
            logger?.didStore(T.self, id: entity.id)
        }
        catch {
            logger?.didFailedToStore(T.self, id: entity.id, error: error)
        }

        return node
    }

    func nodeStore<T: Aggregate>(entity: T, modifiedAt: Stamp) -> EntityNode<T> {
        let node = storage[entity, new: EntityNode(entity, modifiedAt: nil)]
        var entity = entity

        // disable changes while doing the entity update
        node.applyChildrenChanges = false

        // clear all children to avoid a removed child to be kept as child
        node.removeAllChildren()

        for keyPathContainer in entity.nestedEntitiesKeyPaths {
            keyPathContainer.accept(node, entity, modifiedAt, storeVisitor)
        }

        // modify the entity with (potentially) new/different child stored value than what we have
        withUnsafeMutablePointer(to: &entity) {
            let parent = UnsafeMutableRawPointer($0)

            for (_, child) in node.children {
                child.selfAssignTo(parent)
            }
        }

        // TODO: what about if modifiedAt is < but some of the children actually changed?
        do {
            try node.updateEntity(entity, modifiedAt: modifiedAt)
            logger?.didStore(T.self, id: entity.id)
        }
        catch {
            logger?.didFailedToStore(T.self, id: entity.id, error: error)
        }

        node.applyChildrenChanges = true

        return node
    }

}

// MARK: Update

extension IdentityMap {
    /// Updates an **already stored** entity using a closure. This is useful if you don't have a full entity for update
    /// but just a few attributes/modifications.
    ///
    /// - Returns: an `EntityObserver` if the entity is found, nil otherwise
    public func update<T: Identifiable>(_ type: T.Type, id: T.ID, modifiedAt: Stamp = Date().stamp, _ update: Update<T>)
    -> EntityObserver<T>? {
        identityQueue.sync(flags: .barrier) {
            guard var entity = storage[EntityNode<T>.self, id: id]?.ref.value else {
                return nil
            }

            update(&entity)

            return EntityObserver(node: nodeStore(entity: entity, modifiedAt: modifiedAt), queue: observeQueue)
        }
    }

    /// Updates an **already stored** alias using a closure. This is useful if you don't have a full entity for update
    /// but just a few attributes/modifications.
    ///
    /// - Returns: an `EntityObserver` if the entity is found, nil otherwise
    public func update<T: Aggregate>(_ type: T.Type, id: T.ID, modifiedAt: Stamp = Date().stamp, _ update: Update<T>)
    -> EntityObserver<T>? {
        identityQueue.sync(flags: .barrier) {
            guard var entity = storage[EntityNode<T>.self, id: id]?.ref.value else {
                return nil
            }

            update(&entity)

            return EntityObserver(node: nodeStore(entity: entity, modifiedAt: modifiedAt), queue: observeQueue)
        }
    }

    /// Updates an **already stored** alias using a closure.
    /// - Returns: an `EntityObserver` if the entity is found, nil otherwise
    public func update<T: Identifiable>(named: AliasKey<T>, modifiedAt: Stamp = Date().stamp, update: Update<T>)
    -> EntityObserver<T>? {
        identityQueue.sync(flags: .barrier) {
            guard let entity = refAliases[named].value else {
                return nil
            }

            var value = entity.ref.value
            update(&value)
            let node = nodeStore(entity: value, modifiedAt: modifiedAt)

            refAliases.insert(node, key: named)

            return EntityObserver(node: node, queue: observeQueue)
        }
    }

    /// Updates an **already stored** alias using a closure.
    /// - Returns: an `EntityObserver` if the entity is found, nil otherwise
    public func update<T: Aggregate>(named: AliasKey<T>, modifiedAt: Stamp = Date().stamp, update: Update<T>)
    -> EntityObserver<T>? {
        identityQueue.sync(flags: .barrier) {
            guard let entity = refAliases[named].value else {
                return nil
            }

            var value = entity.ref.value
            update(&value)
            let node = nodeStore(entity: value, modifiedAt: modifiedAt)

            return EntityObserver(node: node, queue: observeQueue)
        }
    }

    /// Updates an **already existing** collection alias content
    public func update<C: Collection>(named: AliasKey<C>, modifiedAt: Stamp = Date().stamp, _ update: Update<[C.Element]>)
    -> [EntityObserver<C.Element>]? where C.Element: Identifiable {
        identityQueue.sync(flags: .barrier) {
            guard let entities = refAliases[named].value else {
                return nil
            }

            var values = entities.map(\.ref.value)
            update(&values)

            let nodes = values.map { nodeStore(entity: $0, modifiedAt: modifiedAt) }

            refAliases.insert(nodes, key: named)

            return nodes.map { EntityObserver(node: $0, queue: observeQueue) }
        }
    }

    /// Updates an **already existing** collection alias content
    public func update<C: Collection>(named: AliasKey<C>, modifiedAt: Stamp = Date().stamp, _ update: Update<[C.Element]>)
    -> [EntityObserver<C.Element>]? where C.Element: Aggregate {
        identityQueue.sync(flags: .barrier) {
            guard let entities = self.refAliases[named].value else {
                return nil
            }

            var values = entities.map(\.ref.value)
            update(&values)

            let nodes = values.map { nodeStore(entity: $0, modifiedAt: modifiedAt) }

            refAliases.insert(nodes, key: named)

            return nodes.map { EntityObserver(node: $0, queue: observeQueue) }
        }
    }
}