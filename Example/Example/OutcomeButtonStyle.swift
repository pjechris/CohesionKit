import SwiftUI

struct OutcomeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .font(Font.callout.weight(.bold))
            .padding(.horizontal)
            .padding(.vertical, 4)
            .frame(minWidth: 66)
            .background(Color.yellow)
            .cornerRadius(4)
    }
}
