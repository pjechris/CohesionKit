import Foundation
import Combine
import CohesionKit

class MatchRepository {
    private static let identityMap = IdentityMap()
    private lazy var identityMap = Self.identityMap
    private var cancellables: Set<AnyCancellable> = []
    
    /// load matches with their markets and outcomes from Data.swift
    func loadMatches() -> AnyPublisher<[MatchMarkets], Never> {
        let matches = MatchMarkets.simulatedMatches
        
        return identityMap.store(entities: matches, modifiedAt: MatchMarkets.simulatedFetchedDate.stamp).asPublisher
    }
    
    /// observe primary (first) match market changes (for this sample changes are generated randomely
    /// - Returns: the match with all its markets including updates for primary market
    func observePrimaryMarket(for match: Match) -> AnyPublisher<MatchMarkets, Never> {
        let matchMarket = MatchMarkets.simulatedMatches.first { $0.match.id == match.id }!
        var cancellables: Set<AnyCancellable> = []
        
        for outcome in matchMarket.primaryMarket.outcomes {
            generateRandomChanges(for: outcome)
                .sink(receiveValue: { [identityMap] in
                    _ = identityMap.store(entity: $0)
                })
                .store(in: &cancellables)
        }
        
        return identityMap.find(MatchMarkets.self, id: match.id)!
            .asPublisher
            .handleEvents(receiveCancel: { cancellables.removeAll() })
            .eraseToAnyPublisher()
    }
    
    private func generateRandomChanges(for outcome: Outcome) -> AnyPublisher<Outcome, Never> {
        Timer
            .publish(every: 3, on: .main, in: .common)
            .autoconnect()
            .map { _ in outcome.newOdds(Double.random(in: 0...25)) }
            .prepend(outcome)
            .eraseToAnyPublisher()
    }

}
