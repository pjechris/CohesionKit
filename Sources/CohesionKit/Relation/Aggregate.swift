import Foundation

protocol Aggregate: Identifiable {
    var nestedEntitiesKeyPaths: [PartialIdentifiableKeyPath<Self>] { get }
}
