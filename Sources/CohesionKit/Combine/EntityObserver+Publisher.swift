#if canImport(Combine)
import Combine

extension Observer {
    /// A `Publisher` emitting the observer current value and subscribing to any subsequents new values
    public var publisher: AnyPublisher<T, Never> {
        let subject = CurrentValueSubject<T, Never>(value)
        let subscription = observe(onChange: subject.send)
        
        return subject
            .handleEvents(receiveCancel: { subscription.unsubscribe() })
            .eraseToAnyPublisher()
    }
}

extension Array where Element: Observer {
    /// A `Publisher` emitting each observer current value and subscribing to any subsequents new values
    public var publisher: AnyPublisher<[Element.T], Never> {
        let subject = CurrentValueSubject<[Element.T], Never>(map(\.value))
        
        let subscriptions = indices.map { index in
            self[index].observe {
                subject.value[index] = $0
            }
        }
        
        return subject
            .handleEvents(receiveCancel: { subscriptions.forEach { $0.unsubscribe() } })
            .eraseToAnyPublisher()
    }
}

#endif
