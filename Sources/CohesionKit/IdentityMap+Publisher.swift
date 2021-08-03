import Combine
import CombineExt

// MARK: Publisher extension

public extension IdentityMap {
    /// Add or update an object in the storage with its new value and use current date as object stamp
    func update<S: Sequence>(_ sequence: S, modifiedAt: Stamp = Date().stamp) -> AnyPublisher<[S.Element], Never> where S.Element: Identifiable {
        return sequence
            .map { update($0, modifiedAt: modifiedAt) }
            .combineLatest()
            .eraseToAnyPublisher()
    }

    /// Return a publisher emitting event when receiving update for `id` if an object with such `id` was previously inserted using `update(_:)` method
    func publisherIfPresent<Model: Identifiable>(for model: Model.Type, id: Model.ID) -> AnyPublisher<Model, Never>? {
        self[Model.self, id]?.publisher
    }

    /// Return a publisher emitting event when receiving update for `id`. Note that object might not be present in the storage
    /// at the time where publisher is requested. Thus this publisher *might* never send any value.
    ///
    /// Object is guaranteed to stay in memory as long as someone is using the publisher
    func publisher<Model: Identifiable>(for model: Model.Type, id: Model.ID) -> AnyPublisher<Model, Never> {
        guard let storage = self[Model.self, id] else {
            let storage = Storage<Model>(id: id, identityMap: self)

            self[Model.self, id] = storage

            return storage.publisher
        }

        return storage.publisher
    }

    /// Return a publisher emitting event containing latest elements values.
    /// Note that all elements have to emit at least ONCE before this publisher emitting a value.
    /// - Parameters ids: the elements ids
    func publisher<Element: Identifiable>(for element: [Element].Type, ids: [Element.ID]) -> AnyPublisher<[Element], Never> {
        ids
            .map { publisher(for: Element.self, id: $0) }
            .combineLatest()
    }
}
