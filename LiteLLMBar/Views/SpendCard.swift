import SwiftUI

struct SpendCard: View {
    let title: String
    let amount: Double
    let currencyCode: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(CurrencyFormatter.string(amount, currencyCode: currencyCode))
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText(countsDown: false))
                .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.2), value: amount)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .spendGlassCard(cornerRadius: 16)
    }
}
