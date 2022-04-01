import Foundation
import CohesionKit

struct RootFixture: Aggregate, Equatable {
    let id: Int
    let primitive: String
    var singleNode: SingleNodeFixture
    var optional: OptionalNodeFixture?
    var listNodes: [ListNodeFixture]
    
    var nestedEntitiesKeyPaths: [PartialIdentifiableKeyPath<RootFixture>] {
        [
            .init(\.singleNode),
            .init(\.optional),
            .init(\.listNodes)
        ]
    }
}

struct SingleNodeFixture: Identifiable, Equatable {
    let id: Int
    var primitive: String? = nil
}

struct OptionalNodeFixture: Identifiable, Equatable {
    let id: Int
    var properties: [String: String] = [:]
}

struct ListNodeFixture: Identifiable, Equatable {
    let id: Int
    var key = ""
}
