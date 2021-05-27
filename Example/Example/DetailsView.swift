import Foundation
import SwiftUI

class MatchDetailsViewModel: ObservableObject {
    let match: Match
    @Published var markets: [MarketOutcomes] = []
    private let repository = MatchRepository()

    init(match: Match) {
        self.match = match
    }

    func observe() {
        repository
            .observePrimaryMarket(for: match)
            .receive(on: RunLoop.main)
            .map { $0.markets }
            .assign(to: &$markets)
    }
}

struct MatchDetailsView: View {
    @StateObject var viewModel: MatchDetailsViewModel

    var match: Match { viewModel.match }
    var markets: [MarketOutcomes] { viewModel.markets }

    init(match: Match) {
        _viewModel = StateObject(wrappedValue: MatchDetailsViewModel(match: match))
    }

    var body: some View {
        VStack {
            Text("\(match.team1) - \(match.team2)")
                .font(.title)

            Text("""
This view observe changes for primary market (1N2).
They are triggered every 3 secondes.
If you go back you also see it updated on list view.
""")
                .font(.footnote)
                .italic()

            List {
                ForEach(markets, id: \.market.id) { market in
                    Section(header: Text(market.market.name)) {
                        ForEach(market.outcomes) { outcome in
                            outcomeRow(outcome)
                        }
                    }
                }

            }
        }
        .onAppear { viewModel.observe() }
    }

    @ViewBuilder
    func outcomeRow(_ outcome: Outcome) -> some View {
        HStack {
            Text(outcome.name)
            Spacer()
            Button(action: { }) {
                Text(String(Int(outcome.odds.rounded())))
            }
            .buttonStyle(OutcomeButtonStyle())
        }
    }
}
