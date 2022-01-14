import CohesionKit

enum Relations {
    static let matchMarkets =
        Relation(
            primaryChildPath: \MatchMarkets.match,
            otherChildren: [.init(\.markets, relation: Relations.marketOutcomes)]
        )
    
    static let marketOutcomes =
        Relation(
            primaryChildPath: \MarketOutcomes.market,
            otherChildren: [.init(\.outcomes)]
        )    
}
