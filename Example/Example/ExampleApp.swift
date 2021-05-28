import SwiftUI
import Combine

@main
struct ExampleApp: App {
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
