/// Keep a strong reference on each aliased node
typealias AliasStorage = [String: Any]

extension AliasStorage {
    subscript<T>(_ type: T.Type, key aliasKey: AliasKey<T>) -> EntityNode<AliasContainer<T>>? {
        get { self[key(for: T.self, key: aliasKey)] as? EntityNode<AliasContainer<T>> }
        set { self[key(for: T.self, key: aliasKey)] = newValue }
    }

    private func key<T>(for type: T.Type, alias: AliasKey<T>) -> String {
        "\(type):\(alias.name)"
    }
}
