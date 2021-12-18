import Foundation
import Combine
import CombineExt

typealias StampedObject<D> = (object: D, modifiedAt: Stamp)

/// A "subject" wrapping a `StampedObject` and publishing a new element whenever the value change.
///
/// This "subject" can have only one subscriber
class StampedSubject<T> {
    private let subject: CurrentValueSubject<StampedObject<T>?, Never>
    private(set) var publisher: AnyPublisher<T, Never>!
    private var upstreamCancellable: AnyCancellable?
    
    var value: T? { subject.value?.object }

    /// init an empty storage
    convenience init(id: Any, identityMap: IdentityMap) {
        self.init() { [weak identityMap] in
            identityMap?[T.self, id: id] = nil
        }
    }

    init(remove: @escaping () -> Void) {
        self.subject = CurrentValueSubject(nil)
        self.publisher = subject
            .compactMap { $0?.object }
            .handleEvents(receiveCancel: { [weak self] in
                // avoid some exclusive memory access by first releasing upstream
                // which might itself remove content from identity map
                self?.upstreamCancellable?.cancel()
                remove()
            })
            .share(replay: 1)
            .eraseToAnyPublisher()
    }

    /// Send new input to storage and notify any subscribers when value is updated
    /// - Returns: true if storage was updated. Storage is updated only if `stamp` is sup. to storage stamp
    @discardableResult
    func send(_ input: T, modifiedAt: Stamp) -> Bool {
        guard subject.value.map({ modifiedAt >= $0.modifiedAt }) ?? true else {
            return false
        }

        subject.send((object: input, modifiedAt: modifiedAt))
        return true
    }

    /// Merge value from `upstream` into the storage
    func merge(_ upstream: AnyPublisher<T, Never>, modifiedAt: Stamp) {
        upstreamCancellable = upstream
            .sink(receiveValue: { [weak self] in self?.send($0, modifiedAt: modifiedAt) })
    }
}
