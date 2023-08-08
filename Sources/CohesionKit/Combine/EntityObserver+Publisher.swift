#if canImport(Combine)
import Combine

extension Observer {
    /// A `Publisher` emitting the observer current value and subscribing to any subsequents new values
    public var asPublisher: AnyPublisher<T, Never> {
        let subject = CurrentValueSubject<T?, Never>(nil)
        let subscription = observe(onChange: subject.send)

        return subject
            .compactMap { $0 }
            .handleEvents(receiveCancel: { subscription.unsubscribe() })
            .eraseToAnyPublisher()
    }
}

#endif
