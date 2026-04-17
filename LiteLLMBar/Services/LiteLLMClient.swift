import Foundation
import OSLog

actor LiteLLMClient {
    private let baseURL: URL
    private let apiKeyProvider: @Sendable () async -> String?
    private let session: URLSession
    private let dateFormatter: DateFormatter

    init(
        baseURL: URL,
        apiKeyProvider: @escaping @Sendable () async -> String?,
        session: URLSession? = nil
    ) {
        self.baseURL = baseURL
        self.apiKeyProvider = apiKeyProvider

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 20
        self.session = session ?? URLSession(configuration: configuration)

        let formatter = DateFormatter()
        formatter.calendar = .liteLLMUTC
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        self.dateFormatter = formatter
    }

    func fetchActivity(start: Date, end: Date) async throws -> DailyActivity {
        guard let apiKey = await apiKeyProvider(), !apiKey.isEmpty else {
            throw LiteLLMClientError.missingAPIKey
        }

        var lastError: Error?
        let delays: [Duration] = [.milliseconds(500), .seconds(1), .seconds(2)]

        for attempt in 0...delays.count {
            do {
                return try await performFetch(start: start, end: end, apiKey: apiKey)
            } catch let error as LiteLLMClientError where error.isRetriable && attempt < delays.count {
                lastError = error
                try await Task.sleep(for: delays[attempt])
            } catch let error as URLError where attempt < delays.count {
                lastError = error
                try await Task.sleep(for: delays[attempt])
            } catch {
                throw error
            }
        }

        throw lastError ?? LiteLLMClientError.invalidResponse
    }

    private func performFetch(start: Date, end: Date, apiKey: String) async throws -> DailyActivity {
        let url = try activityURL(start: start, end: end)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        Logger.network.info("Fetching LiteLLM activity from \(url.absoluteString, privacy: .public)")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LiteLLMClientError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            do {
                return try JSONDecoder().decode(DailyActivity.self, from: data)
            } catch {
                throw LiteLLMClientError.decoding(error.localizedDescription)
            }
        case 401:
            throw LiteLLMClientError.unauthorized
        case 429, 500..<600:
            throw LiteLLMClientError.httpStatus(httpResponse.statusCode, responsePreview(from: data))
        default:
            throw LiteLLMClientError.httpStatus(httpResponse.statusCode, responsePreview(from: data))
        }
    }

    private func activityURL(start: Date, end: Date) throws -> URL {
        let endpoint = baseURL.appending(path: "user/daily/activity")
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw LiteLLMClientError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "start_date", value: dateFormatter.string(from: start)),
            URLQueryItem(name: "end_date", value: dateFormatter.string(from: end))
        ]

        guard let url = components.url else {
            throw LiteLLMClientError.invalidURL
        }

        return url
    }

    private func responsePreview(from data: Data) -> String {
        String(data: data.prefix(400), encoding: .utf8) ?? ""
    }
}

enum LiteLLMClientError: LocalizedError, Sendable {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case unauthorized
    case httpStatus(Int, String)
    case decoding(String)

    var isRetriable: Bool {
        switch self {
        case .httpStatus(let status, _):
            status == 429 || (500..<600).contains(status)
        case .missingAPIKey, .invalidURL, .invalidResponse, .unauthorized, .decoding:
            false
        }
    }

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "No LiteLLM API key is configured."
        case .invalidURL:
            "The LiteLLM base URL is invalid."
        case .invalidResponse:
            "LiteLLM returned an invalid response."
        case .unauthorized:
            "API key invalid — please update in Settings."
        case .httpStatus(let status, let preview):
            preview.isEmpty ? "LiteLLM returned HTTP \(status)." : "LiteLLM returned HTTP \(status): \(preview)"
        case .decoding(let message):
            "Could not read LiteLLM usage data: \(message)"
        }
    }
}
