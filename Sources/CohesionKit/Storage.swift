import Foundation
import Combine
import CombineExt

typealias StampedObject<D> = (object: D, modifiedAt: Stamp)

/// A "subject" wrapping a `StampedObject` and publishing a new element whenever the value change.
///
/// This "subject" can have only one subscriber
class Storage<T> {
    private let subject: CurrentValueSubject<StampedObject<T>?, Never>
    private(set) var publisher: AnyPublisher<StampedObject<T>, Never>!
    private var upstreamCancellable: AnyCancellable?
    
    var value: T? { subject.value?.object }
    var modifiedAt: Stamp { subject.value?.modifiedAt ?? 0 }

    /// init an empty storage
    convenience init(id: Any, identityMap: IdentityStore) {
        self.init() { [weak identityMap] in
            identityMap?[T.self, id: id] = nil
        }
    }

    init(remove: @escaping () -> Void) {
        self.subject = CurrentValueSubject(nil)
        self.publisher = subject
            .compactMap { $0 }
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
    func send(_ input: StampedObject<T>) -> Bool {
        guard modifiedAt < input.modifiedAt else {
            return false
        }

        subject.send(input)
        return true
    }

    /// Merge value from `upstream` into the storage
    func merge(_ upstream: AnyPublisher<StampedObject<T>, Never>) {
        upstreamCancellable = upstream
            .sink(receiveValue: { [weak self] in self?.send($0) })
    }
}

class EntityNode<T> {
    typealias SubscribedChild = (subscription: Subscription, node: Any)
    
    let ref: Ref<T>
    private var children: [AnyKeyPath: SubscribedChild] = [:]
    
    init(ref: Ref<T>) {
        self.ref = ref
    }
    
    func observeChild<C>(_ childNode: EntityNode<C>, for keyPath: KeyPath<T, C>) {
        if let subscribedChild = children[keyPath]?.node as? EntityNode<C>, subscribedChild == childNode {
            return
        }
        
        let observer = childNode.ref.addObserver { [ref] newValue in
            withUnsafeMutablePointer(to: &ref.value) {
                let pointer = UnsafeMutableRawPointer($0)
                
                pointer.assign(newValue, to: keyPath)
            }
        }
        
        children[keyPath] = (subscription: observer, node: childNode)
    }
}

extension EntityNode: Hashable {
    static func==(lhs: EntityNode<T>, rhs: EntityNode<T>) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }
}
