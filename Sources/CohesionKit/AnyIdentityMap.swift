import Combine

/// A type erased identity map
protocol AnyIdentityMap {
    func publisher<Model: Identifiable>(for model: Model.Type, id: Model.ID) -> AnyPublisher<Model, Never>

    func update<Model: Identifiable>(_ newObject: Model, stamp: Any) -> AnyPublisher<Model, Never>

    func update<Model: IdentityGraph>(_ object: Model, stamp: Any) -> AnyPublisher<Model, Never>

    func update<Model: IdentityGraph>(_ object: [Model], stampedAt: Any) -> AnyPublisher<[Model], Never>
}
