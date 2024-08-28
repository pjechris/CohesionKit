/// Keep a strong reference on each aliased node
typealias AliasStorage = [String: any AnyEntityNode]

extension AliasStorage {
    subscript<T>(_ aliasKey: AliasKey<T>) -> EntityNode<AliasContainer<T>>? {
        get { self[buildKey(for: T.self, key: aliasKey)] as? EntityNode<AliasContainer<T>> }
        set { self[buildKey(for: T.self, key: aliasKey)] = newValue }
    }

    subscript<T>(safe key: AliasKey<T>, onChange onChange: ((EntityNode<AliasContainer<T>>) -> Void)? = nil) -> EntityNode<AliasContainer<T>> {
        mutating get {
            let storeKey = buildKey(for: T.self, key: key)
            return self[key: key, default: EntityNode(AliasContainer(key: key), key: storeKey, modifiedAt: nil, onChange: onChange)]
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

    private func buildKey<T>(for type: T.Type, key: AliasKey<T>) -> String {
        "\(type):\(key.name)"
    }
}
