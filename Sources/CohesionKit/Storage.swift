//
//  File.swift
//  
//
//  Created by JC on 06/05/2021.
//

import Foundation
import Combine

class Storage<T: Identifiable> {
    let subject: CurrentValueSubject<T, Never>
    weak var identityMap: IdentityMap?
    
    lazy var publisher: AnyPublisher<T, Never> = subject
        .handleEvents(receiveCancel: { [identityMap, subject] in
            identityMap?.remove(subject.value)
        })
        .multicast(PassthroughSubject.init)
        .autoconnect()
        .eraseToAnyPublisher()
    
    init(object: T, identityMap: IdentityMap) {
        self.subject = CurrentValueSubject(object)
        self.identityMap = identityMap
    }
}
