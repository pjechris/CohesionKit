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
}

private class VisitMock: NestedEntitiesVisitor {
    var visitAggregateCalled = false
    func visit<Root, T>(context: EntityContext<Root, T>, entity: T) where T : Aggregate {
        visitAggregateCalled = true
    }
    
    func visit<Root, T>(context: EntityContext<Root, T>, entity: T) where T : Identifiable {
        
    }
    
    func visit<Root, T>(context: EntityContext<Root, T>, entity: T?) where T : Identifiable {
        
    }
    
    func visit<Root, T>(context: EntityContext<Root, T>, entity: T?) where T : Aggregate {
        
    }
    
    func visit<Root, C>(context: EntityContext<Root, C>, entities: C)
    where C : Collection, C.Element : Aggregate, C.Index : Hashable {
        
    }
    
    func visit<Root, C>(context: EntityContext<Root, C>, entities: C)
    where C : Collection, C.Element : Identifiable, C.Index : Hashable {
        
    }
    
}
