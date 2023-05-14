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
            VStack(alignment: .leading, spacing: 0) {
                Text("This view observe changes for the first market (1N2).")
                Text("New values are triggered every 3 secondes.")
                Text("If you go back you will see updated values on list view.")
            }
            .font(Font.footnote.italic())
            .foregroundColor(.secondary)
            .padding(.leading)

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
        .navigationTitle(Text("\(match.team1) - \(match.team2)"))
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
