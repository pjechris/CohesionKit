import CohesionKit

extension MatchMarkets: Relational {
    var primaryPath: KeyPath<MatchMarkets, Match> {
        \.match
    }

    var relations: [RelationKeyPath<MatchMarkets>] {
        [.init(\.match), .init(\.markets)]
    }

    func reduce(changes: KeyPathUpdates<MatchMarkets>) -> MatchMarkets {
        MatchMarkets(match: changes.match, markets: changes.markets)
    }
    
}

extension MarketOutcomes: Relational {
    var primaryPath: KeyPath<MarketOutcomes, Market> {
        \.market
    }

    var relations: [RelationKeyPath<MarketOutcomes>] {
        [.init(\.market), .init(\.outcomes)]
    }

    func reduce(changes: KeyPathUpdates<MarketOutcomes>) -> MarketOutcomes {
        MarketOutcomes(market: changes.market, outcomes: changes.outcomes)
    }
}
