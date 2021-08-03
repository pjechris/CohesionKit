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

        return identityMap.update(matches, modifiedAt: MatchMarkets.simulatedFetchedDate.stamp)
    }

    /// observe primary (first) match market changes (for this sample changes are generated randomely
    /// - Returns: the match with all its markets including updates for primary market
    func observePrimaryMarket(for match: Match) -> AnyPublisher<MatchMarkets, Never> {
        let data = MatchMarkets.simulatedMatches.first { $0.match.id == match.id }!

        return data
            .primaryMarket
            .outcomes
            .map { outcome in self.randomChanges(for: outcome) }
            .combineLatest()
            .map { [identityMap] in identityMap.update($0) }
            .map { [identityMap] _ in identityMap.publisher(for: MatchMarkets.self, id: match.id) }
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
