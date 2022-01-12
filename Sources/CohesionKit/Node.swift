import Foundation
import Combine

class NodeStorage<T> {
  typealias ChildPublishers = [PartialKeyPath<T>:AnyPublisher<(Any, Stamp), Never>]
  
  var value: T? { subject.value?.object }
  var modifiedAt: Stamp? { subject.value?.modifiedAt }
//  var children: ChildPublishers = [:]
  
  private(set) var publisher: AnyPublisher<StampedObject<T>, Never>!
  private let subject: CurrentValueSubject<StampedObject<T>?, Never>
  private var cancellables: [PartialKeyPath<T>:AnyCancellable] = [:]
  private var upstreamCancellable: AnyCancellable?
  
  /// init an empty storage
  convenience init(id: Any, identityMap: IdentityMap) {
    self.init() { [weak identityMap] in
      identityMap?[T.self, id: id] = nil
    }
  }
  
  init(value: StampedObject<T>? = nil, remove: @escaping () -> Void) {
    self.subject = CurrentValueSubject(value)
    self.publisher = subject
      .compactMap { $0 }
      .handleEvents(receiveCancel: { [weak self] in
        // avoid some exclusive memory access by first releasing upstream
        // which might itself remove content from identity map
        self?.cancellables.removeAll()
        self?.upstreamCancellable?.cancel()
        remove()
      })
      .share(replay: 1)
      .eraseToAnyPublisher()
  }
  
  func subscribe(_ input: StampedObject<T>, children: ChildPublishers) {
    
    for (keyPath, child) in children {
      cancellables[keyPath] = child
        .sink { [weak self] in
          self?.send($0, keyPath: keyPath)
        }
    }
  }
  
  func send<Child>(_ child: StampedObject<Child>, keyPath: PartialKeyPath<T>) {
    guard modifiedAt.map({ $0 < child.modifiedAt }) ?? true else {
      return
    }
    
    withUnsafeMutablePointer(to: &subject.value) {
      UnsafeMutableRawPointer($0)
        .advanced(by: MemoryLayout<T>.offset(of: keyPath)!)
        .assumingMemoryBound(to: Child.self)
        .pointee = child.object
      
      $0.pointee?.modifiedAt = child.modifiedAt
    }    
  }
  
  @discardableResult
  func send(_ input: StampedObject<T>) -> Bool {
    guard modifiedAt.map({ $0 < input.modifiedAt }) ?? true else {
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
