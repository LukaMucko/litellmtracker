import SwiftUI

struct PopoverView: View {
    @Environment(SpendStore.self) private var store

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            content
        }
        .frame(width: 340)
        .padding(20)
        .background {
            if AccessibilitySettings.reduceTransparency {
                Color(nsColor: .windowBackgroundColor)
            }
        }
        .task {
            await store.refreshIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.loadState {
        case .needsConfiguration:
            OnboardingView()
        case .idle, .loading, .loaded, .failed:
            SpendDashboardView()
        }
    }
}
