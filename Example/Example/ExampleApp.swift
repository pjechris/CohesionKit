import SwiftUI
import CohesionKit
import Combine
import CombineExt


class Test: ObservableObject {
    @Published var trades: Set<LastPriceResponse.Trade> = []
    
    var repository = TradeRepository()
    var cancellables: Set<AnyCancellable> = []
    
    func onAppear() {
        repository
            .follow(symbol: "AAPL")
            .receive(on: RunLoop.main)
            .sink(receiveValue: { self.trades.update(with: $0) })
            .store(in: &cancellables)
    }
    
    func removeAll() {
        cancellables.removeAll()
    }
}

@main
struct ExampleApp: App {
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }
    }
}
