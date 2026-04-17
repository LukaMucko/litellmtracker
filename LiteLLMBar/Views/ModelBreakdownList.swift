import SwiftUI

struct ModelBreakdownList: View {
    let models: [ModelSpend]
    let currencyCode: String

    @Namespace private var rowNamespace

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Top models")
                .font(.headline)

            GlassEffectContainer(spacing: 8) {
                if models.isEmpty {
                    Text("No model spend yet")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .spendGlassCard(cornerRadius: 12)
                } else {
                    VStack(spacing: 8) {
                        ForEach(models) { model in
                            ModelSpendRow(model: model, currencyCode: currencyCode)
                                .spendGlassCard(cornerRadius: 12)
                                .glassEffectID(model.id, in: rowNamespace)
                        }
                    }
                }
            }
        }
    }
}

private struct ModelSpendRow: View {
    let model: ModelSpend
    let currencyCode: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(model.model)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text("\(CurrencyFormatter.compactCount(model.tokens)) tokens · \(model.requests) requests")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                Text(CurrencyFormatter.string(model.spend, currencyCode: currencyCode))
                    .font(.callout)
                    .fontWeight(.semibold)
                    .monospacedDigit()

                if model.cachedTokens > 0 {
                    Text("💾 \(CurrencyFormatter.compactCount(model.cachedTokens))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .padding(12)
    }
}
