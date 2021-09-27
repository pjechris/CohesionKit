import Combine
import CombineExt

public struct Relation<Element, ElementIdentity: Identifiable> {
    /// key path to whose id will be used as `Element` identity
    let primaryKeyPath: KeyPath<Element, ElementIdentity>
    
    var idKeyPath: KeyPath<Element, ElementIdentity.ID> { primaryKeyPath.appending(path: \.id) }
    
    /// object with their own identity contained in `Element` and that should be stored
    /// apart (to track them idepedently)
    let identities: [RelationKeyPath<Element>]
    
    /// create a new `Element` based on updates on item relations
    let reduce: (KeyPathUpdates<Element>) -> Element
    
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
