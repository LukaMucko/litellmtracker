import SwiftUI

struct SettingsView: View {
    @Environment(SpendStore.self) private var store

    @State private var baseURL = ""
    @State private var refreshIntervalSeconds = 300
    @State private var currencyCode = "USD"
    @State private var launchAtLogin = false
    @State private var statusMessage: String?
    @State private var isRefreshing = false

    private let intervalPresets: [(label: String, seconds: Int)] = [
        ("10 seconds", 10),
        ("30 seconds", 30),
        ("1 minute", 60),
        ("5 minutes", 300),
        ("15 minutes", 900),
        ("30 minutes", 1800),
        ("1 hour", 3600),
    ]

    var body: some View {
        Form {
            Section("Connection") {
                TextField("Base URL", text: $baseURL)
                    .textContentType(.URL)

                Text("API key is read from LITELLM_API_KEY env var or \(APIKeyStore.configPath).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Refresh") {
                Picker("Interval", selection: $refreshIntervalSeconds) {
                    ForEach(intervalPresets, id: \.seconds) { preset in
                        Text(preset.label).tag(preset.seconds)
                    }
                }

                Picker("Currency", selection: $currencyCode) {
                    Text("USD ($)").tag("USD")
                    Text("EUR (€)").tag("EUR")
                }
                .pickerStyle(.segmented)
            }

            Section("System") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        setLaunchAtLogin(enabled)
                    }
            }

            if let statusMessage {
                Section {
                    Text(statusMessage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                HStack {
                    Button {
                        save()
                    } label: {
                        Label("Save", systemImage: "checkmark")
                    }
                    .buttonStyle(.glassProminent)

                    Button {
                        Task { await saveAndRefresh() }
                    } label: {
                        if isRefreshing {
                            ProgressView().controlSize(.small)
                        } else {
                            Label("Test & Refresh", systemImage: "arrow.clockwise")
                        }
                    }
                    .buttonStyle(.glass)
                    .disabled(isRefreshing)

                    Spacer()

                    Button {
                        store.openDashboard(baseURLString: baseURL)
                    } label: {
                        Label("Open Dashboard", systemImage: "safari")
                    }
                    .buttonStyle(.glass)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .padding()
        .onAppear(perform: load)
    }

    private func load() {
        baseURL = store.baseURLString
        refreshIntervalSeconds = store.refreshIntervalSeconds
        currencyCode = store.currencyCode
        launchAtLogin = LaunchAtLogin.isEnabled
    }

    private func save() {
        store.updateConfiguration(
            baseURLString: baseURL,
            refreshIntervalSeconds: refreshIntervalSeconds,
            currencyCode: currencyCode
        )
        statusMessage = "Settings saved."
    }

    @MainActor
    private func saveAndRefresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        store.updateConfiguration(
            baseURLString: baseURL,
            refreshIntervalSeconds: refreshIntervalSeconds,
            currencyCode: currencyCode
        )
        await store.refresh()
        statusMessage = "Refresh complete."
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LaunchAtLogin.setEnabled(enabled)
            statusMessage = LaunchAtLogin.statusDescription
        } catch {
            launchAtLogin = LaunchAtLogin.isEnabled
            statusMessage = error.localizedDescription
        }
    }
}
