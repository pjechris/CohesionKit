import Combine
import CombineExt

/// A model having relationships you want to store separately into an `IdentityMap`
public protocol Relational {
    associatedtype ID: Hashable

    /// key path to an `Ìdentity.ID` property which represent this map
    var idKeyPath: KeyPath<Self, ID> { get }

    /// identities contained into the object that should be mapped
    var relations: [IdentityKeyPath<Self>] { get }

    /// return a new instance of Self after having applied changes
    func reduce(changes: KeyPathUpdates<Self>) -> Self
}

extension Relational {
    // don't use `id` naming in case it's already used by the object
    var primaryID: ID { self[keyPath: idKeyPath] }
}

extension Relational {
    /// Recursively update each object subpaths
    /// - Returns: a Publisher triggering every time a sub path is updated. Returned object is updated with triggered data
    func store(in identityMap: IdentityMap, modifiedAt: Stamp) -> AnyPublisher<Self, Never> {
        relations
            .map { identityPath in
                identityPath
                    .update(self, identityMap, modifiedAt)
                    .map { (identityPath.keyPath, $0) }
            }
            .combineLatest()
            // aggregate updates if multiple children are updated at once
            .debounce(for: 0.1, scheduler: DispatchQueue.global(qos: .utility))
            .map { reduce(changes: KeyPathUpdates(values: Dictionary(uniqueKeysWithValues: $0))) }
            .prepend(self)
            .eraseToAnyPublisher()
    }
}
