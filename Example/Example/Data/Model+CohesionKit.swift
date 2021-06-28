import CohesionKit

extension MatchMarkets: IdentityGraph {
    var idKeyPath: KeyPath<MatchMarkets, Match.ID> {
        \.match.id
    }

    var identityPaths: [IdentityKeyPath<MatchMarkets>] {
        [.init(\.match), .init(\.markets)]
    }

    func reduce(changes: IdentityValues<MatchMarkets>) -> MatchMarkets {
        MatchMarkets(match: changes.match, markets: changes.markets)
    }
    
}

extension MarketOutcomes: IdentityGraph {
    var idKeyPath: KeyPath<MarketOutcomes, Market.ID> {
        \.market.id
    }

    var identityPaths: [IdentityKeyPath<MarketOutcomes>] {
        [.init(\.market), .init(\.outcomes)]
    }

    func reduce(changes: IdentityValues<MarketOutcomes>) -> MarketOutcomes {
        MarketOutcomes(market: changes.market, outcomes: changes.outcomes)
    }
}
