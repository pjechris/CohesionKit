import Foundation

/// This file contain fake data used to mimick a server

extension Market: ExpressibleByStringLiteral {
    init(stringLiteral value: StringLiteralType) {
        self.init(id: UUID().uuidString, name: value)
    }
}

extension Outcome: ExpressibleByStringLiteral {
    /// for the demo, init an outcome with odds at 0
    init(stringLiteral value: StringLiteralType) {
        self.init(id: UUID().uuidString, name: value, odds: 0)
    }
}

extension MatchMarkets {
    /// This is a date to simulate a fetched date time for data
    static let simulatedFetchedDate = Date()

    static let simulatedMatches: [MatchMarkets] = [
        .init(match: Match(id: UUID().uuidString, team1: "PSG", team2: "Lille"),
              markets: [
                .init(market: "1N2", outcomes: ["1", "N", "2"]),
                .init(market: "Exact Score", outcomes: ["1-0", "1-1", "0-1", "2-0", "2-2", "0-2"])
              ]),

        .init(match: Match(id: UUID().uuidString, team1: "Real Madrid", team2: "FC Barcelone"),
              markets: [
                .init(market: "1N2", outcomes: ["1", "N", "2"]),
                .init(market: "Goal for both teams", outcomes: ["Yes", "No"])
              ]),

        .init(match: Match(id: UUID().uuidString, team1: "Liverpool", team2: "Manchester City"),
              markets: [
                .init(market: "1N2", outcomes: ["1", "N", "2"]),
                .init(market: "Double chance", outcomes: ["Liverpool or draw", "Manchester City or draw"])
              ]),

        .init(match: Match(id: UUID().uuidString, team1: "Bayern Munich", team2: "Borussia Dortmund"),
              markets: [
                .init(market: "1N2", outcomes: ["1", "N", "2"]),
                .init(market: "Goal total", outcomes: ["> 1", "> 2", "> 3"])
              ])
    ]
}
