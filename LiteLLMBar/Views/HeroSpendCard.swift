import SwiftUI

struct HeroSpendCard: View {
    let spend: Double
    let cachedTokens: Int
    let totalTokens: Int
    let currencyCode: String
    let isLoading: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Today")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()

                if isLoading {
                    Text("Updating")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(CurrencyFormatter.string(spend, currencyCode: currencyCode))
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: false))
                    .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.2), value: spend)

                if totalTokens > 0 {
                    Text("\(CurrencyFormatter.compactCount(totalTokens)) tok")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            Text("💾 \(CurrencyFormatter.compactCount(cachedTokens)) cached")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .scaleEffect(isHovered && !reduceMotion && !AccessibilitySettings.reduceTransparency ? 1.02 : 1.0)
        .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.2), value: isHovered)
        .spendGlassCard(cornerRadius: 16, tint: .accentColor, interactive: true)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
