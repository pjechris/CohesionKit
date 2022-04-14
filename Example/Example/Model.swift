import Foundation
import CohesionKit

struct Match: Identifiable {
    let id: String
    let team1: String
    let team2: String
}

struct Market: Identifiable {
    let id: String
    let name: String
}

struct Outcome: Identifiable {
    let id: String
    let name: String
    let odds: Double

    func newOdds(_ odds: Double) -> Outcome {
        Outcome(id: id, name: name, odds: odds)
    }
}

struct MatchMarkets: Aggregate {
    var id: Match.ID { match.id }

    let match: Match
    let markets: [MarketOutcomes]

    var primaryMarket: MarketOutcomes {
        // this is a sample project, we just consider that there is always at least one market
        markets.first!
    }

    var nestedEntitiesKeyPaths: [PartialIdentifiableKeyPath<MatchMarkets>] {[
        .init(\.match),
        .init(\.markets)
    ]}
}

struct MarketOutcomes: Aggregate {
    var id: Market.ID { market.id }

    let market: Market
    let outcomes: [Outcome]
    
    var nestedEntitiesKeyPaths: [PartialIdentifiableKeyPath<Self>] {[
        .init(\.market),
        .init(\.outcomes)
    ]}
}
