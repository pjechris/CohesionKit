import SwiftUI

struct ContentView: View {
    @StateObject var test = Test()

    var body: some View {
        List {
            ForEach(Array(test.trades)) { trade in
                VStack(alignment: .leading, spacing: 8) {
                    Text(trade.id)
                        .bold()
                    Text(String(trade.v))
                }
            }
        }
        .navigationBarItems(trailing: Button(action: test.removeAll) {
            Text("Remove all")
        })
        .onAppear(perform: test.onAppear)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
