//
//  File.swift
//  
//
//  Created by JC on 06/05/2021.
//

import Foundation
import Combine
import CombineExt

struct StampedObject<D, Stamp> {
    let object: D
    let stamp: Stamp
}

class Storage<T, Stamp: Comparable> {
    // TODO: Set as private
    let subject: CurrentValueSubject<StampedObject<T, Stamp>?, Never>
    let publisher: AnyPublisher<T, Never>
    private var upstreamCancellable: AnyCancellable?

    /// init storage with a initial value for a `Idenfitiable` object
    convenience init(object: T, stamp: Stamp, identityMap: IdentityMap<Stamp>) where T: Identifiable {
        self.init(StampedObject(object: object, stamp: stamp)) { [weak identityMap] in
            identityMap?.remove(object)
        }
    }

    /// init an empty storage for a `Idenfitiable` object
    convenience init(id: T.ID, identityMap: IdentityMap<Stamp>) where T: Identifiable {
        self.init(nil) { [weak identityMap] in
            identityMap?.remove(for: T.self, id: id)
        }
    }

    /// init an empty storage for an `IdentityGraph` object using its id
    convenience init(id: T.ID, identityMap: IdentityMap<Stamp>) where T: IdentityGraph {
        self.init(nil) { [weak identityMap] in
            identityMap?.remove(for: T.self, id: id)
        }
    }

    private init(_ object: StampedObject<T, Stamp>?, remove: @escaping () -> Void) {
        self.subject = CurrentValueSubject(object)
        self.publisher = subject
            .compactMap { $0?.object }
            .handleEvents(receiveCancel: {
                remove()
            })
            .share(replay: 1)
            .eraseToAnyPublisher()
    }

    /// Send new input to storage and notify any subscribers when value is updated
    /// - Returns: true if storage was updated. Storage is updated only if `stampedAt` is sup. to storage stamp
    @discardableResult
    func send(_ input: T, stampedAt stamp: Stamp) -> Bool {
        guard subject.value.map({ stamp >= $0.stamp }) ?? true else {
            return false
        }

        subject.send(StampedObject(object: input, stamp: stamp))
        return true
    }

    /// Forward a `Publisher` and send its value to Storage
    func forward(_ upstream: AnyPublisher<T, Never>, stampedAt stamp: Stamp) {
        upstreamCancellable = upstream
            .sink(receiveValue: { [weak self] in self?.send($0, stampedAt: stamp) })
    }
}
