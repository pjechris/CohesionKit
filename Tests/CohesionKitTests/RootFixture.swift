import Foundation
import CohesionKit

struct AFixture: Aggregate {
    var id: BFixture.ID { b.id }
    var b: BFixture

    var nestedEntitiesKeyPaths: [PartialIdentifiableKeyPath<Self>] {
        [.init(\.b)]
    }
}

struct BFixture: Aggregate {
    var id: SingleNodeFixture.ID { c.id }
    var c: SingleNodeFixture

    var nestedEntitiesKeyPaths: [PartialIdentifiableKeyPath<Self>] {
        [.init(\.c)]
    }
}

struct RootFixture: Aggregate, Equatable {
    let id: Int
    let primitive: String
    var singleNode: SingleNodeFixture
    var optional: OptionalNodeFixture?
    var listNodes: [ListNodeFixture]
    var enumWrapper: EnumFixture?

    var nestedEntitiesKeyPaths: [PartialIdentifiableKeyPath<Self>] {
        [
            .init(\.singleNode),
            .init(\.optional),
            .init(\.listNodes),
            .init(wrapper: \.enumWrapper)
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

 enum EnumFixture: Equatable, EntityWrapper {
    case single(SingleNodeFixture)

    var singleNode: SingleNodeFixture? {
        get {
            switch self {
                case .single(let value):
                return value
            }
        }
        set {
            if let newValue {
                self = .single(newValue)
            }
        }
    }

    func wrappedEntitiesKeyPaths<Root>(relativeTo parent: WritableKeyPath<Root, Self>) -> [PartialIdentifiableKeyPath<Root>] {
        [
            PartialIdentifiableKeyPath(parent.appending(path: \.singleNode))
        ]
    }
}
