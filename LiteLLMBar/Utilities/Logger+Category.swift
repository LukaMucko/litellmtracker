import Foundation
import OSLog

extension Logger {
    private static var subsystem: String {
        Bundle.main.bundleIdentifier ?? "at.aithyra.litellm.menubar"
    }

    static let network = Logger(subsystem: subsystem, category: "network")
    static let app = Logger(subsystem: subsystem, category: "app")

    static func redacted(_ message: String) -> String {
        message.replacingOccurrences(
            of: #"Bearer\s+sk-[A-Za-z0-9_\-.]+"#,
            with: "Bearer <redacted>",
            options: .regularExpression
        )
    }
}
