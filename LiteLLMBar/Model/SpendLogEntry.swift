import Foundation

struct SpendLogEntry: Decodable, Sendable {
    let startTime: Date
    let spend: Double
    let model: String?

    private enum CodingKeys: String, CodingKey {
        case startTime
        case spend
        case cost   // some LiteLLM versions use "cost" instead
        case model
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        let raw = (try? c.decode(String.self, forKey: .startTime)) ?? ""
        startTime = Self.parseDate(raw) ?? Date()

        // Prefer "spend", fall back to "cost"
        let s = (try? c.decode(Double.self, forKey: .spend))
            ?? (try? c.decode(Double.self, forKey: .cost))
            ?? 0
        spend = s

        model = try? c.decode(String.self, forKey: .model)
    }

    private static func parseDate(_ raw: String) -> Date? {
        var s = raw.trimmingCharacters(in: .whitespaces)

        // ISO 8601 with T separator
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: s) { return d }
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: s) { return d }

        // LiteLLM/Python datetime uses space separator: "2024-04-17 14:32:10.123456+00:00"
        // Normalize space → T so ISO8601DateFormatter can handle it
        if let i = s.firstIndex(of: " ") { s.replaceSubrange(i...i, with: "T") }

        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: s) { return d }
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: s) { return d }

        // No timezone suffix — assume UTC
        if !s.contains("+") && !s.hasSuffix("Z") {
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = iso.date(from: s + "Z") { return d }
            iso.formatOptions = [.withInternetDateTime]
            if let d = iso.date(from: s + "Z") { return d }
        }

        return nil
    }
}
