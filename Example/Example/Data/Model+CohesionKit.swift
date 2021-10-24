import CohesionKit

enum Relations {
    static let matchMarkets =
        Relation(
            primaryChildPath: \.match,
            otherChildren: [.init(\.markets, relation: Relations.marketOutcomes)],
            reduce: { MatchMarkets(match: $0.match, markets: $0.markets) }
        )
    
    static let marketOutcomes =
        Relation(
            primaryChildPath: \.market,
            otherChildren: [.init(\.outcomes)],
            reduce: { MarketOutcomes(market: $0.market, outcomes: $0.outcomes) }
        )
}
