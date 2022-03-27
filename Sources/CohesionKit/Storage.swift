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

private protocol AnyEntityNode: AnyObject {
    var value: Any { get }
}

class EntityNode<T>: AnyEntityNode {
    private typealias SubscribedChild = (unsubscribe: Unsubscription, node: AnyEntityNode)
    
    var applyChildrenChanges = true

    /// An observable entity reference
    private let ref: Ref<T>
    /// last time the ref.value was changed. Any subsequent change must have a bigger `modifiedAt` value to be applied
    private var modifiedAt: Stamp
    /// entity children
    private var children: [PartialKeyPath<T>: SubscribedChild] = [:]
    fileprivate var value: Any { ref.value }
    
    init(_ entity: T, modifiedAt: Stamp) {
        self.ref = Ref(value: entity)
        self.modifiedAt = modifiedAt
    }
    
    deinit {
        removeAllChildren()
    }
    
    func updateEntity(_ entity: T, modifiedAt newModifiedAt: Stamp) {
        guard newModifiedAt > modifiedAt else {
            return
        }
        
        modifiedAt = newModifiedAt
        ref.value = entity
    }
    
    func removeAllChildren() {
        children.values.forEach { $0.unsubscribe() }
    }
    
    func observeChild<C>(_ childNode: EntityNode<C>, for keyPath: KeyPath<T, C>) {
        if let subscribedChild = children[keyPath]?.node as? EntityNode<C>, subscribedChild == childNode {
            return
        }
        
        let unsubscription = childNode.ref.addObserver { [unowned self] newValue in
            guard self.applyChildrenChanges else {
                return
            }

            withUnsafeMutablePointer(to: &self.ref.value) {
                let pointer = UnsafeMutableRawPointer($0)
                
                pointer.assign(newValue, to: keyPath)
            }
        }
        
        children[keyPath]?.unsubscribe()
        children[keyPath] = (unsubscribe: unsubscription, node: childNode)
    }
    
    /// return each children node value mapped to its given keypath
    func childrenValues() -> [PartialKeyPath<T>: Any] {
        children.mapValues(\.node.value)
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
