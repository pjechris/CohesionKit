import Foundation
import CohesionKit

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

 enum EnumFixture: Equatable, EntityEnumWrapper {
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

    func wrappedEntitiesKeyPaths<Root>(for root: WritableKeyPath<Root, Self>) -> [PartialIdentifiableKeyPath<Root>] {
        [
            PartialIdentifiableKeyPath(root.appending(path: \.singleNode))
        ]
    }
}