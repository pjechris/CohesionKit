/// A value representing an Entity or set of Entity
public struct AliasKey<T>: Hashable {
    let name: String

    var key: String {
        "\(type(of: T.self)).\(name)"
    }

    public init(named value: String) {
        self.name = value
    }
}
