import Combine
import CombineExt

public typealias IdentifiableRelation<Identity: Identifiable> = Relation<Identity, Identity>

public struct Relation<Element, Identity: Identifiable> {
    /// key path to `Element` id
    let idKeyPath: KeyPath<Element, Identity.ID>
        
    /// object with their own identity contained in `Element` and that should be stored
    /// apart (to track them idepedently)
    let identities: [RelationKeyPath<Element>]
    
    /// a function creating a new `Element` from updates
    let reduce: (KeyPathUpdates<Element>) -> Element
    
    /// - Parameter primaryKeyPath: key path to a `Identifiable` attribute which will be used as `Element` identity
    /// - Parameter identities: identities contained in Element. Don't include the one referenced by `primaryKeyPath`
    public init(primaryKeyPath: KeyPath<Element, Identity>,
                identities: [RelationKeyPath<Element>],
                reduce: @escaping (KeyPathUpdates<Element>) -> Element) {
        
        let isKeyPathSelf = primaryKeyPath == \Element.self
        // remove any identity relating to primaryKeyPath
        let identities = identities.filter { $0.keyPath != primaryKeyPath }
        
        self.idKeyPath = primaryKeyPath.appending(path: \.id)
        // add primaryKeyPath in identities if it's not self
        self.identities = identities + (isKeyPathSelf ? [] : [RelationKeyPath(primaryKeyPath)])
        self.reduce = reduce
    }
    
    public init() where Element == Identity {
        self.init(
            primaryKeyPath: \.self,
            identities: [],
            reduce: { $0.root }
        )
    }
}
