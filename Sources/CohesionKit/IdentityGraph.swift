import Combine
import CombineExt

public protocol IdentityGraph {
    associatedtype ID: Hashable

    /// key path to an `Ìdentity.ID` property which represent this map
    var idKeyPath: KeyPath<Self, ID> { get }

    /// identities contained into the object that should be mapped
    var identityKeyPaths: [IdentityKeyPath<Self>] { get }

    /// return a new instance of Self after having applied changes
    func reduce(changes: IdentityValues<Self>) -> Self
}

extension IdentityGraph {
    // don't use `id` naming in case it's already used by the object
    var idValue: ID { self[keyPath: idKeyPath] }
}

extension IdentityGraph {
    /// Recursively update each object subpaths
    /// - Returns: a Publisher triggering every time a sub path is updated. Returned object is updated with triggered data
    func update(in identityMap: AnyIdentityMap, stamp: Any) -> AnyPublisher<Self, Never> {
        identityKeyPaths
            .map { identityPath in
                identityPath
                    .update(self, identityMap, stamp)
                    .map { (identityPath.keyPath, $0) }
            }
            .combineLatest()
            .map { reduce(changes: IdentityValues(values: Dictionary(uniqueKeysWithValues: $0))) }
            .eraseToAnyPublisher()
    }
}
