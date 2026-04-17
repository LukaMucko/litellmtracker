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

    // Runs a login shell to pick up env vars from ~/.zshrc / ~/.bash_profile etc.,
    // then injects any found LITELLM_API_KEY into the current process environment
    // so the next call to load() finds it via ProcessInfo.
    static func refreshFromShell() {
        for shell in ["/bin/zsh", "/bin/bash"] {
            guard FileManager.default.fileExists(atPath: shell) else { continue }
            let task = Process()
            task.executableURL = URL(fileURLWithPath: shell)
            task.arguments = ["-l", "-c", "printenv LITELLM_API_KEY"]
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = Pipe()
            guard (try? task.run()) != nil else { continue }
            task.waitUntilExit()
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !output.isEmpty {
                setenv("LITELLM_API_KEY", output, 1)
                return
            }
        }
    }

    static var configPath: String {
        "~/.config/litellmtracker/api_key"
    }
}
