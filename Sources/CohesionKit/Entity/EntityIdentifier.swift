import Foundation

/// A unique identifier for an object identified by an id
struct EntityIdentifier {
  let value: String

  init<T>(of entityType: T.Type, id: Any) {
    self.value = "\(entityType)__\(id)"
  }

  init<T: Identifiable>(_ entity: T) {
    self.init(of: type(of: entity), id: entity.id)
  }
}
