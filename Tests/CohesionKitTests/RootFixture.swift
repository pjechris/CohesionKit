import Foundation
import CohesionKit

struct RootFixture: Aggregate {
    let id: Int
    let primitive: String
    let singleNode: SingleNodeFixture
    var optional: OptionalNodeFixture?
    var listNodes: [ListNodeFixture]
    
    let nestedEntitiesKeyPaths: [PartialIdentifiableKeyPath<RootFixture>] = [
        .init(\.singleNode),
//        .init(\.optional),
        .init(\.listNodes)
    ]
}

struct SingleNodeFixture: Identifiable {
    let id: Int
}

struct OptionalNodeFixture: Identifiable {
    let id: Int
}

struct ListNodeFixture: Identifiable {
    let id: Int
}
