/// A value representing an Entity or set of Entity
public struct AliasKey<T>: ExpressibleByStringLiteral, Hashable {
    let name: String
    
    public init(stringLiteral value: StringLiteralType) {
        self.name = value
    }
}
