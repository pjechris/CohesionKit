import Foundation

/// a function transforming `Updated<Element>` into `Element`
public typealias Updater<Element> = (Updated<Element>) -> Element

/// A container with updates made on `Root`
///
/// You can access updates using `Root` member names: `Updated<User>(..).username`
@dynamicMemberLookup
public struct Updated<Root> {
  let root: Root
  let updates: [PartialKeyPath<Root>: Any]

  /// return registered update or value from root
  public subscript<T>(dynamicMember keyPath: KeyPath<Root, T>) -> T {
    get { updates[keyPath] as? T ?? root[keyPath: keyPath] }
  }

  func reduce() -> Root {
    var root = root

    withUnsafeMutablePointer(to: &root) {
      let pointer = UnsafeMutableRawPointer($0)

      for (keyPath, value) in updates {
        pointer.assign(value, to: keyPath)
      }
    }

    return root
  }

  static func assign<Value>(_: Value.Type) {

  }
}

extension UnsafeMutableRawPointer {
  func assign<Root>(_ value: Any, to keyPath: PartialKeyPath<Root>) {
    func open<Value>(_: Value.Type) {
      assign(value as! Value, to: unsafeDowncast(keyPath, to: KeyPath<Root, Value>.self))
    }

    _openExistential(type(of: keyPath).valueType, do: open)
  }

  func assign<Root, Value>(_ value: Value, to keyPath: KeyPath<Root, Value>) {
    advanced(by: MemoryLayout<Root>.offset(of: keyPath)!)
      .assumingMemoryBound(to: Value.self)
      .pointee = value
  }
}
