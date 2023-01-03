import Foundation

/// An `Identifiable` model containing nested models
public protocol Aggregate: Identifiable {
    /// keypaths to nested models
    var nestedEntitiesKeyPaths: [PartialIdentifiableKeyPath<Self>] { get }
}
