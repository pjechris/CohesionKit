import CohesionKit

enum Relations {
    static let matchMarket =
        Relation(
            primaryChildPath: \.match,
            otherChildren: [.init(\.markets, relation: Relations.marketOutcome)],
            reduce: { MatchMarkets(match: $0.match, markets: $0.markets) }
        )
    
    static let marketOutcome =
        Relation(
            primaryChildPath: \.market,
            otherChildren: [.init(\.outcomes)],
            reduce: { MarketOutcomes(market: $0.market, outcomes: $0.outcomes) }
        )    
}
