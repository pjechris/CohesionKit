//
//  File.swift
//  
//
//  Created by JC on 06/05/2021.
//

import Foundation
import Combine

struct StampedObject<D, Stamp> {
    let object: D
    let stamp: Stamp
}

class Storage<T: Identifiable, Stamp: Comparable> {
    let subject: CurrentValueSubject<StampedObject<T, Stamp>?, Never>
    let publisher: AnyPublisher<T, Never>

    convenience init(object: T, stamp: Stamp, identityMap: IdentityMap<Stamp>) {
        self.init(object: .init(object: object, stamp: stamp), id: object.id, identityMap: identityMap)
    }

    convenience init(id: T.ID, identityMap: IdentityMap<Stamp>) {
        self.init(object: nil, id: id, identityMap: identityMap)
    }

    private init(object: StampedObject<T, Stamp>?, id: T.ID, identityMap: IdentityMap<Stamp>) {
        self.subject = CurrentValueSubject(object)
        self.publisher = subject
            .compactMap { $0?.object }
            .handleEvents(receiveCancel: { [weak identityMap, id] in
                identityMap?.remove(for: T.self, id: id)
            })
            .multicast(PassthroughSubject.init)
            .autoconnect()
            .eraseToAnyPublisher()
    }
}
