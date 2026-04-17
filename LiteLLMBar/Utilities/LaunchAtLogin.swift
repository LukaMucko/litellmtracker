import Foundation
import ServiceManagement

enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static var statusDescription: String {
        switch SMAppService.mainApp.status {
        case .enabled:
            "Launch at login is enabled."
        case .notRegistered:
            "Launch at login is disabled."
        case .requiresApproval:
            "Approve launch at login in System Settings."
        case .notFound:
            "Launch at login is not available for this build."
        @unknown default:
            "Launch at login status is unknown."
        }
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            guard SMAppService.mainApp.status != .enabled else { return }
            try SMAppService.mainApp.register()
        } else {
            guard SMAppService.mainApp.status != .notRegistered else { return }
            try SMAppService.mainApp.unregister()
        }
    }
}
