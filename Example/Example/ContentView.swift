import SwiftUI

class MatchListViewModel: ObservableObject {
    @Published var matches: [MatchMarkets] = []

    let repository = MatchRepository()

    func load() {
        repository
            .loadMatches()
            .assign(to: &$matches)
    }
}

struct ContentView: View {
    @StateObject var viewModel = MatchListViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("CohesionKit sample app")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading)

            Spacer(minLength: 16)

            VStack(alignment: .leading, spacing: 4) {
                Text("This app shows how you can use CohesionKit too keep data synchronized during your app lifecyle.")
                Text("Go on detail views to trigger \"realtime\" events.")
            }
            .font(Font.footnote.italic())
            .foregroundColor(.secondary)
            .padding(.leading)

            Spacer(minLength: 8)

            List {
                ForEach(viewModel.matches, id: \.match.id) {
                    let match = $0.match
                    let outcomes = $0.markets.first!.outcomes

                    NavigationLink(destination: MatchDetailsView(match: match)) {
                        VStack(spacing: 16) {
                            Text("\(match.team1) - \(match.team2)")
                                .bold()

                            HStack(spacing: 16) {
                                ForEach(outcomes) { outcome in
                                    VStack {
                                        Text(outcome.name)
                                            .font(.caption2)

                                        Button(action: { }) {
                                            Text(String(Int(outcome.odds.rounded())))
                                        }
                                        .buttonStyle(OutcomeButtonStyle())
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
            }
        }
        .navigationTitle(
            Text("Easy Bet")
        )
        .onAppear(perform: viewModel.load)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
