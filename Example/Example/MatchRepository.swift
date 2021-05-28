import Foundation
import Combine
import CohesionKit
import CombineExt

class MatchRepository {
    private static let identityMap = IdentityMap<Date>()
    private lazy var identityMap = Self.identityMap
    private var cancellables: Set<AnyCancellable> = []

    /// load matches with their markets and outcomes from Data.swift
    func loadMatches() -> AnyPublisher<[MatchMarkets], Never> {
        let stamp = MatchMarkets.simulatedFetchedDate

        return MatchMarkets.simulatedData.map { matchMarkets -> AnyPublisher<MatchMarkets, Never> in
            let match = identityMap.update(matchMarkets.match, stamp: stamp)
            let markets = matchMarkets.markets.map { marketOutcomes -> AnyPublisher<MarketOutcomes, Never> in
                let market = identityMap.update(marketOutcomes.market, stamp: stamp)
                let outcomes = marketOutcomes.outcomes.map { identityMap.update($0, stamp: stamp) }

                return market
                    .combineLatest(outcomes.combineLatest())
                    .map { MarketOutcomes(market: $0.0, outcomes: $0.1) }
                    .eraseToAnyPublisher()
            }

            return match.combineLatest(markets.combineLatest())
                .map { MatchMarkets(match: $0.0, markets: $0.1) }
                .eraseToAnyPublisher()
        }
        .combineLatest()
        .eraseToAnyPublisher()
    }

    /// observe primary (first) match market changes (for this sample changes are generated randomely
    /// - Returns: the match with all its markets including updates for primary market
    func observePrimaryMarket(for match: Match) -> AnyPublisher<MatchMarkets, Never> {
        let data = MatchMarkets.simulatedData.filter { $0.match.id == match.id }.first!

        return generateMarketChanges(for: data.primaryMarket)
            .map { market in
                MatchMarkets(
                    match: data.match,
                    markets: data.markets.map { market.market.id == $0.market.id ? market : $0 }
                )
            }
            .eraseToAnyPublisher()
    }

    /// Generate outcomes changes for the market every 3 secondes
    private func generateMarketChanges(for market: MarketOutcomes) -> AnyPublisher<MarketOutcomes, Never> {
        // Generate random values for testing
        for outcome in market.outcomes {
            Timer
                .publish(every: 3, on: .main, in: .common)
                .autoconnect()
                .map { _ in outcome.newOdds(Double.random(in: 0...25)) }
                .sink(receiveValue: { [identityMap] in
                        identityMap.updateIfPresent($0)

                })
                .store(in: &cancellables)
        }

        return identityMap
            .publisher(for: Market.self, id: market.market.id)
            .combineLatest(
                market.outcomes
                    .map { identityMap.publisher(for: Outcome.self, id: $0.id) }
                    .combineLatest()
            )
            .map {
                MarketOutcomes(market: $0.0, outcomes: $0.1)

            }
            .eraseToAnyPublisher()
    }
}
