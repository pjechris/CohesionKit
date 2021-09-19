import CohesionKit

extension MatchMarkets: Relational {
    var primaryKeyPath: KeyPath<MatchMarkets, Match> {
        \.match
    }

    var relations: [IdentityKeyPath<MatchMarkets>] {
        [.init(\.match), .init(\.markets)]
    }

    func reduce(changes: KeyPathUpdates<MatchMarkets>) -> MatchMarkets {
        MatchMarkets(match: changes.match, markets: changes.markets)
    }
    
}

extension MarketOutcomes: Relational {
    var primaryKeyPath: KeyPath<MarketOutcomes, Market> {
        \.market
    }

    var relations: [IdentityKeyPath<MarketOutcomes>] {
        [.init(\.market), .init(\.outcomes)]
    }

    func reduce(changes: KeyPathUpdates<MarketOutcomes>) -> MarketOutcomes {
        MarketOutcomes(market: changes.market, outcomes: changes.outcomes)
    }
}
