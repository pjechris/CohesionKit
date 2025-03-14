/// Keep a strong reference on each aliased node
typealias AliasStorage = [Identifier: any AnyEntityNode]

extension AliasStorage {
    subscript<T>(_ aliasKey: AliasKey<T>) -> EntityNode<AliasContainer<T>>? {
        get { self[Identifier(for: T.self, key: aliasKey)] as? EntityNode<AliasContainer<T>> }
        set { self[Identifier(for: T.self, key: aliasKey)] = newValue }
    }

    subscript<T>(safe key: AliasKey<T>) -> EntityNode<AliasContainer<T>> {
      mutating get {
        let storeKey = Identifier(for: T.self, key: key)
        return self[key: key, default: EntityNode(AliasContainer(key: key), id: storeKey, modifiedAt: nil)]
      }
    }

    subscript<T>(key key: AliasKey<T>, default defaultValue: @autoclosure () -> EntityNode<AliasContainer<T>>)
    -> EntityNode<AliasContainer<T>> {
        mutating get {
            guard let node = self[key] else {
                let node = defaultValue()

                self[key] = node

                return node
            }

            return node
        }
    }
}
