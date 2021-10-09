import Combine
import CombineExt

public typealias RelationIdentifiable<Element: Identifiable> = Relation<Element, Element>

public struct Relation<Element, ElementIdentity: Identifiable> {
    /// key path to an `Identifiable` object whose id will be used as identity
    public let primaryKeyPath: KeyPath<Element, ElementIdentity>
        
    /// object with their own identity contained in `Element` and that should be stored
    /// apart (to track them idepedently)
    public let identities: [RelationKeyPath<Element>]
    
    /// a function creating a new `Element` from updates
    public let reduce: (KeyPathUpdates<Element>) -> Element
    
    var idKeyPath: KeyPath<Element, ElementIdentity.ID> { primaryKeyPath.appending(path: \.id) }
    
    public init(primaryKeyPath: KeyPath<Element, ElementIdentity>,
                identities: [RelationKeyPath<Element>],
                reduce: @escaping (KeyPathUpdates<Element>) -> Element) {
        
        self.primaryKeyPath = primaryKeyPath
        self.identities = identities
        self.reduce = reduce
    }
    
    public init() where Element == ElementIdentity {
        self.init(
            primaryKeyPath: \Element.self,
            identities: [.init(\Element.self)],
            reduce: { $0[\Element.self] }
        )
    }
}
