//
//  File.swift
//  
//
//  Created by JC on 06/05/2021.
//

import Foundation
import Combine

class Storage<T: Identifiable> {
    let subject: CurrentValueSubject<T?, Never>
    private let id: T.ID
    weak var identityMap: IdentityMap?
    
    lazy var publisher: AnyPublisher<T, Never> = subject
        .compactMap { $0 }
        .handleEvents(receiveCancel: { [identityMap, subject, id] in
            identityMap?.remove(for: T.self, id: id)
        })
        .multicast(PassthroughSubject.init)
        .autoconnect()
        .eraseToAnyPublisher()

    convenience init(object: T, identityMap: IdentityMap) {
        self.init(object: object, id: object.id, identityMap: identityMap)
    }

    convenience init(id: T.ID, identityMap: IdentityMap) {
        self.init(object: nil, id: id, identityMap: identityMap)
    }

    private init(object: T?, id: T.ID, identityMap: IdentityMap) {
        self.subject = CurrentValueSubject(object)
        self.id = id
        self.identityMap = identityMap
    }
}
