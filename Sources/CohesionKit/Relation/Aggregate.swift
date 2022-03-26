import Foundation

public protocol Aggregate: Identifiable {
    var nestedEntitiesKeyPaths: [PartialIdentifiableKeyPath<Self>] { get }
}
