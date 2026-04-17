import SwiftUI

struct MenuBarLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .monospacedDigit()
            .contentTransition(.numericText())
            .animation(.spring(duration: 0.5, bounce: 0.2), value: title)
    }
}
