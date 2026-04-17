import Foundation

enum APIKeyStore {
    static func load() -> String? {
        if let key = ProcessInfo.processInfo.environment["LITELLM_API_KEY"], !key.isEmpty {
            return key
        }

        let file = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/litellmtracker/api_key")
        let key = try? String(contentsOf: file, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return key?.isEmpty == false ? key : nil
    }

    static var configPath: String {
        "~/.config/litellmtracker/api_key"
    }
}
