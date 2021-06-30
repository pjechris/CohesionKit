import Combine

/// A type erased identity map
protocol AnyIdentityMap {
    func publisher<Model: Identifiable>(for model: Model.Type, id: Model.ID) -> AnyPublisher<Model, Never>

    func update<Model: Identifiable>(_ newObject: Model, stamp: Any) -> AnyPublisher<Model, Never>

    func update<Model: IdentityGraph>(_ object: Model, stamp: Any) -> AnyPublisher<Model, Never>

    func update<S: Sequence>(_ sequence: S, stamp: Any) -> AnyPublisher<[S.Element], Never> where S.Element: IdentityGraph
}

extension IdentityMap: AnyIdentityMap {
    func update<Model: Identifiable>(_ newObject: Model, stamp: Any) -> AnyPublisher<Model, Never> {
        guard let stamp = stamp as? Stamp else {
            return publisher(for: Model.self, id: newObject.id)
        }

        return update(newObject, stamp: stamp)
    }

    func update<Model: IdentityGraph>(_ object: Model, stamp: Any) -> AnyPublisher<Model, Never> {
        return update(object, stamp: stamp as! Stamp)
    }

    func update<S: Sequence>(_ sequence: S, stamp: Any) -> AnyPublisher<[S.Element], Never> where S.Element: IdentityGraph {
        guard let stamp = stamp as? Stamp else {
            return sequence
                .map(\.idValue)
                .map { publisher(for: S.Element.self, id: $0) }
                .combineLatest()
                .eraseToAnyPublisher()
        }

        return update(sequence, stamp: stamp)
    }
}
