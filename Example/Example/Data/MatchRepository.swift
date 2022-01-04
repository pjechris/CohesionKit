import Foundation
import Combine
import CohesionKit
import CombineExt

class MatchRepository {
    private static let identityMap = IdentityMap()
    private lazy var identityMap = Self.identityMap
    private var cancellables: Set<AnyCancellable> = []

    /// load matches with their markets and outcomes from Data.swift
    func loadMatches() -> AnyPublisher<[MatchMarkets], Never> {
        let matches = MatchMarkets.simulatedMatches

        return identityMap.store(
          matches,
          using: Relations.matchMarkets,
          modifiedAt: MatchMarkets.simulatedFetchedDate.stamp
        )
    }

    /// observe primary (first) match market changes (for this sample changes are generated randomely
    /// - Returns: the match with all its markets including updates for primary market
    func observePrimaryMarket(for match: Match) -> AnyPublisher<MatchMarkets, Never> {
        let data = MatchMarkets.simulatedMatches.first { $0.match.id == match.id }!
        let outcomes = data.primaryMarket.outcomes.map { identityMap.get(for: Outcome.self, id: $0.id) ?? $0 }

        return outcomes
            .map { outcome in self.randomChanges(for: outcome) }
            .combineLatest()
            .map { [identityMap] in identityMap.store($0) }
            .map { [identityMap] _ in identityMap.publisher(using: Relations.matchMarkets, id: match.id) }
            .switchToLatest()
            .eraseToAnyPublisher()
    }

    private func randomChanges(for outcome: Outcome) -> AnyPublisher<Outcome, Never> {
        Timer
            .publish(every: 3, on: .main, in: .common)
            .autoconnect()
            .map { _ in outcome.newOdds(Double.random(in: 0...25)) }
            .prepend(outcome)
            .eraseToAnyPublisher()
    }

}
