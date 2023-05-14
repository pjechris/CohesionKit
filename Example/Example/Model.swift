import Foundation
import CohesionKit

/// A match is a sport game between two teams
struct Match: Identifiable {
    let id: String
    let team1: String
    let team2: String
}

/// A market is a type of bet. For instance: who's going to win
struct Market: Identifiable {
    let id: String
    let name: String
}

/// An outcome is a possible market outcome
struct Outcome: Identifiable {
    let id: String
    let name: String
    /// "probability" this outcome would happen
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
