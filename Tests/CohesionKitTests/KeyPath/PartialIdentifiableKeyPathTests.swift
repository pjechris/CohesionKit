import XCTest
@testable import CohesionKit

class PartialIdentifiableKeyPathTests: XCTestCase {
  func test_accept_aggregate_callVisitAnAggregate() {
    let visitMock = VisitMock()
    let partialIdentifiable = PartialIdentifiableKeyPath(\RootFixture.self)
    let entity = RootFixture(id: 1, primitive: "", singleNode: SingleNodeFixture(id: 1), optional: nil, listNodes: [])

    partialIdentifiable.accept(EntityNode(entity, modifiedAt: 0), entity, 0, visitMock)

    XCTAssertTrue(visitMock.visitAggregateCalled)
  }

  func test_accept_wrapper_visitWrappedValues() {
    let visitMock = VisitMock()
    let partialIdentifiable = PartialIdentifiableKeyPath(wrapper: \RootFixture.enumWrapper)
    let entity = RootFixture(
      id: 1,
      primitive: "",
      singleNode: SingleNodeFixture(id: 1),
      optional: nil,
      listNodes: [],
      enumWrapper: .single(SingleNodeFixture(id: 2))
    )

    visitMock.visitorCalledWith = { visitedEntity, keyPath in
      XCTAssertEqual(visitedEntity as? SingleNodeFixture, entity.enumWrapper?.singleNode)
      XCTAssertEqual(keyPath, \RootFixture.enumWrapper!.singleNode)
    }

    partialIdentifiable.accept(EntityNode(entity, modifiedAt: 0), entity, 0, visitMock)
  }
}

private class VisitMock: NestedEntitiesVisitor {
    var visitAggregateCalled = false
    var visitorCalledWith: ((Any?, AnyKeyPath) -> Void)?
    func visit<Root, T>(context: EntityContext<Root, T>, entity: T) where T : Aggregate {
        visitAggregateCalled = true
        visitorCalledWith?(entity, context.keyPath)
    }

    func visit<Root, T>(context: EntityContext<Root, T>, entity: T) where T : Identifiable {
      visitorCalledWith?(entity, context.keyPath)
    }

    func visit<Root, T>(context: EntityContext<Root, T?>, entity: T?) where T : Identifiable {
      visitorCalledWith?(entity, context.keyPath)
    }

    func visit<Root, T>(context: EntityContext<Root, T?>, entity: T?) where T : Aggregate {
      visitorCalledWith?(entity, context.keyPath)
    }

    func visit<Root, C>(context: EntityContext<Root, C>, entities: C)
    where C : MutableCollection, C.Element : Aggregate, C.Index : Hashable {
      visitorCalledWith?(entities, context.keyPath)
    }

    func visit<Root, C>(context: EntityContext<Root, C>, entities: C)
    where C : MutableCollection, C.Element : Identifiable, C.Index : Hashable {
      visitorCalledWith?(entities, context.keyPath)
    }

}
