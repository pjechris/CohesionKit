import Combine
import CombineExt

/// a relation for one single `Identifiable` object with no children
public typealias SingleRelation<Identity: Identifiable> = Relation<Identity, Identity>

/// A representation of `Root` structure for storing in a `IdentityMap`
public struct Relation<Element, Identity: Identifiable> {
    /// key path to `Element` id
    let idKeyPath: KeyPath<Element, Identity.ID>
        
    /// children stored in Root that should be stored separately in identity map (i.e relational or `Identifiable` objects)
    let children: [RelationKeyPath<Element>]
    
    /// a function to create a new `Element` instance based on updates from children
    let reduce: Updater<Element>
    
    /// - Parameter primaryPath: key path to a `Identifiable` attribute which will be used as `Element` identity
    /// - Parameter children: identities contained in Element. Don't include the one referenced by `primaryPath`
    public init(primaryPath: KeyPath<Element, Identity>,
                children: [RelationKeyPath<Element>],
                reduce: @escaping Updater<Element>) {
        
        let isKeyPathSelf = primaryPath == \Element.self
        // remove any identity relating to primaryPath
        let children = children.filter { $0.keyPath != primaryPath }
        
        self.idKeyPath = primaryPath.appending(path: \.id)
        // add primaryPath in identities if it's not self
        self.children = children + (isKeyPathSelf ? [] : [RelationKeyPath(primaryPath)])
        self.reduce = reduce
    }
    
    public init() where Element == Identity {
        self.init(
            primaryPath: \.self,
            children: [],
            reduce: { $0.root }
        )
    }
}
