/// Keep a strong reference on each aliased node
typealias AliasStorage = [AnyHashable: AnyRef]

extension AliasStorage {
    subscript<T>(key: AliasKey<T>) -> Observable<EntityNode<T>?> {
        mutating get {
            if let store = self[AnyHashable(key)] as? Observable<EntityNode<T>?> {
                return store
            }

            let store: Observable<EntityNode<T>?> = Observable(value: nil)
            self[AnyHashable(key)] = store

            return store

        }
    }

    subscript<C: Collection>(key: AliasKey<C>) -> Observable<[EntityNode<C.Element>]?> {
        mutating get {
            if let store = self[AnyHashable(key)] as? Observable<[EntityNode<C.Element>]?> {
                return store
            }

            let store: Observable<[EntityNode<C.Element>]?> = Observable(value: nil)
            self[AnyHashable(key)] = store

            return store

        }
    }

    mutating func insert<T>(_ node: EntityNode<T>, key: AliasKey<T>) {
        self[key].value = node
    }

    mutating func insert<C: Collection>(_ nodes: [EntityNode<C.Element>], key: AliasKey<C>) {
        self[key].value = nodes
    }

    mutating func remove<T>(for key: AliasKey<T>) {
        (self[AnyHashable(key)] as? Observable<EntityNode<T>?>)?.value = nil
    }

    mutating func remove<C: Collection>(for key: AliasKey<C>) {
        (self[AnyHashable(key)] as? Observable<[EntityNode<C.Element>]?>)?.value = nil
    }
}
