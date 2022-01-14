import Combine
import CombineExt

/// A representation of `Element` structure for storing in `IdentityMap`
public struct Relation<Element, ID: Hashable> {
  /// key path to `Element` id
  let idKeyPath: KeyPath<Element, ID>

  /// children stored in Root that should be stored separately in identity map (i.e relational or `Identifiable` objects)
  let allChildren: [RelationKeyPath<Element>]

  /// - Parameter primaryChildPath: key path to a `Identifiable` attribute which will be used as `Element` identity
  /// - Parameter otherChildren: identities contained in Element that should be stored separately. Don't include the one referenced by `primaryPath`
  /// - Parameter reduce: Swift has no proper reflection API so we need you to tell us how to create `Element` when
  /// receiving updates (basically: `MyStruct(param1: $0.param1)`)
  public init<Identity: Identifiable>(
    primaryChildPath: KeyPath<Element, Identity>,
    otherChildren: [RelationKeyPath<Element>],
    reduce: @escaping Updater<Element>
  ) where Identity.ID == ID {

    self.init(primaryChildPath: primaryChildPath, otherChildren: otherChildren)
  }

  public init<Identity: Identifiable>(
    primaryChildPath: KeyPath<Element, Identity>,
    otherChildren: [RelationKeyPath<Element>]
  ) where Identity.ID == ID {

    let isKeyPathSelf = primaryChildPath == \Element.self
    // remove any identity relating to primaryPath
    let otherChildren = otherChildren.filter { $0.keyPath != primaryChildPath }

    self.idKeyPath = primaryChildPath.appending(path: \.id)
    // add primaryPath in identities if it's not self
    self.allChildren = otherChildren + (isKeyPathSelf ? [] : [RelationKeyPath(primaryChildPath)])
  }

  /// Create a `Relation` for a single `Identifiable` object with no children
  public init() where Element: Identifiable, Element.ID == ID {
    self.init(primaryChildPath: \.self, otherChildren: [])
  }

  /// Create a `Relation` for a single `Identifiable` object with no children. Same
  /// as calling `init()` with no arguments
  public static func single() -> Self where Element: Identifiable, Element.ID == ID {
    self.init()
  }
}
