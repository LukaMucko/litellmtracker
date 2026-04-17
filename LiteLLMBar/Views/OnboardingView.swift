import SwiftUI

struct OnboardingView: View {
    @Environment(SpendStore.self) private var store
    @State private var baseURL = ""
    @State private var isSaving = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("LiteLLM spend")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Set your API key as an environment variable, then click Connect.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let banner = store.bannerMessage {
                Text(banner)
                    .font(.callout)
                    .foregroundStyle(.black)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .spendGlassCard(cornerRadius: 12, tint: .yellow, interactive: true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Set one of these before launching:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("export LITELLM_API_KEY=sk-...")
                    .font(.system(.caption, design: .monospaced))
                    .padding(6)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                Text("or create \(APIKeyStore.configPath)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Base URL")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("https://llms.apps.aithyra.at", text: $baseURL)
                    .textFieldStyle(.roundedBorder)
            }

            Button {
                Task { await connect() }
            } label: {
                if isSaving {
                    ProgressView()
                        .controlSize(.small)
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Connect", systemImage: "key.fill")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.glassProminent)
            .disabled(isSaving)

            HStack {
                Button {
                    store.openDashboard(baseURLString: baseURL)
                } label: {
                    Label("Open Dashboard", systemImage: "safari")
                }
                .buttonStyle(.glass)

                SettingsLink {
                    Label("Settings", systemImage: "gearshape")
                }
                .buttonStyle(.glass)
            }
            .labelStyle(.titleAndIcon)
        }
        .onAppear {
            baseURL = store.baseURLString
        }
    }

    @MainActor
    private func connect() async {
        isSaving = true
        defer { isSaving = false }
        store.updateConfiguration(
            baseURLString: baseURL,
            refreshIntervalSeconds: store.refreshIntervalSeconds,
            currencyCode: store.currencyCode
        )
        await store.refreshKeyAndConnect()
    }
}
