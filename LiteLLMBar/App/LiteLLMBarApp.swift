import SwiftUI

@main
struct LiteLLMBarApp: App {
    @State private var store = SpendStore()

    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .environment(store)
        } label: {
            MenuBarLabel(title: store.menuBarTitle)
                .contextMenu {
                    Button("Refresh") {
                        Task { await store.refresh() }
                    }
                    Divider()
                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(store)
        }
    }
}
