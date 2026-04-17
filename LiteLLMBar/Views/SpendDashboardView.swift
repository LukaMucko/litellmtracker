import AppKit
import SwiftUI

struct SpendDashboardView: View {
    @Environment(SpendStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let message = store.bannerMessage {
                BannerView(message: message)
            }

            HeroSpendCard(
                spend: store.todaySpend,
                cachedTokens: store.cachedTokens,
                totalTokens: store.totalTokens,
                currencyCode: store.currencyCode,
                isLoading: store.loadState.isLoading
            )

            HStack(spacing: 12) {
                SpendCard(title: "7 days", amount: store.last7Spend, currencyCode: store.currencyCode)
                SpendCard(title: "Month", amount: store.monthSpend, currencyCode: store.currencyCode)
            }

            SpendCard(title: "All time", amount: store.allTimeSpend, currencyCode: store.currencyCode)

            SpendChartView(
                summary: store.summary,
                currencyCode: store.currencyCode,
                eurRate: store.eurRate
            )

            ModelBreakdownList(models: store.topModels, currencyCode: store.currencyCode)

            footer
            actions
        }
    }

    private var footer: some View {
        HStack {
            Text(store.lastRefreshText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            if store.loadState.isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 8) {
            Button {
                Task {
                    await store.refresh()
                }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)

            Button {
                store.openDashboard()
            } label: {
                Label("Open Dashboard", systemImage: "safari")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)

            HStack(spacing: 8) {
                SettingsLink {
                    Label("Settings", systemImage: "gearshape")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)

                Button {
                    NSApp.terminate(nil)
                } label: {
                    Label("Quit", systemImage: "power")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
            }
        }
    }
}

#Preview {
    PopoverView()
        .environment(SpendStore.mock())
}

private struct BannerView: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.black)
            Text(message)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .font(.callout)
        .foregroundStyle(.black)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .spendGlassCard(cornerRadius: 12, tint: .yellow, interactive: true)
    }
}
