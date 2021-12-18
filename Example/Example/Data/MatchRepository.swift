import Foundation
import Combine
import CohesionKit
import CombineExt

class MatchRepository {
    private static let registry = RegistryIdentityMap(identityMap: IdentityMap())
    private lazy var registry = Self.registry
    private var cancellables: Set<AnyCancellable> = []

    /// load matches with their markets and outcomes from Data.swift
    func loadMatches() -> AnyPublisher<[MatchMarkets], Never> {
        let matches = MatchMarkets.simulatedMatches

        return registry
            .identityMap(for: Relations.matchMarket)
            .store(matches, modifiedAt: MatchMarkets.simulatedFetchedDate.stamp)
    }

    /// observe primary (first) match market changes (for this sample changes are generated randomely
    /// - Returns: the match with all its markets including updates for primary market
    func observePrimaryMarket(for match: Match) -> AnyPublisher<MatchMarkets, Never> {
        let data = MatchMarkets.simulatedMatches.first { $0.match.id == match.id }!
        let outcomes = data.primaryMarket.outcomes.map { registry.identityMap(for: Outcome.self).get(for: $0.id) ?? $0 }

        return outcomes
            .map { outcome in self.randomChanges(for: outcome) }
            .combineLatest()
            .map { [registry] in registry.identityMap(for: Outcome.self).store($0) }
            .map { [registry] _ in registry.identityMap(for: Relations.matchMarket).publisher(for: match.id) }
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
