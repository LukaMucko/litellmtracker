import AppKit
import Foundation
import Observation
import OSLog

enum LoadState {
    case idle
    case loading
    case loaded
    case failed(Error)
    case needsConfiguration

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

@MainActor
@Observable
final class SpendStore {
    private enum DefaultsKey {
        static let baseURL = "baseURL"
        static let refreshIntervalSeconds = "refreshIntervalSeconds"
        static let currencyCode = "currencyCode"
    }

    private static let defaultBaseURL = "https://llms.apps.aithyra.at"

    private(set) var summary = SpendSummary.empty
    private(set) var lastRefresh: Date?
    private(set) var loadState: LoadState = .idle
    private(set) var hasAPIKey = false
    private(set) var bannerMessage: String?
    private(set) var eurRate: Double = 1.0

    var baseURLString: String
    var refreshIntervalSeconds: Int
    var currencyCode: String

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var refreshTask: Task<Void, Never>?
    @ObservationIgnored private var wakeTask: Task<Void, Never>?
    @ObservationIgnored private var isRefreshing = false
    @ObservationIgnored private let exchangeRateService = ExchangeRateService()

    private var currencyMultiplier: Double { currencyCode == "EUR" ? eurRate : 1.0 }

    var todaySpend: Double { summary.todaySpend * currencyMultiplier }
    var last7Spend: Double { summary.last7Spend * currencyMultiplier }
    var monthSpend: Double { summary.monthSpend * currencyMultiplier }
    var allTimeSpend: Double { summary.allTimeSpend * currencyMultiplier }
    var cachedTokens: Int { summary.cachedTokens }
    var totalTokens: Int { summary.totalTokens }
    var topModels: [ModelSpend] {
        let mult = currencyMultiplier
        guard mult != 1.0 else { return summary.topModels }
        return summary.topModels.map {
            ModelSpend(model: $0.model, spend: $0.spend * mult,
                       requests: $0.requests, tokens: $0.tokens, cachedTokens: $0.cachedTokens)
        }
    }

    var menuBarTitle: String {
        hasAPIKey ? "💸 \(CurrencyFormatter.string(todaySpend, currencyCode: currencyCode))" : "💸 --"
    }

    var lastRefreshText: String {
        guard let lastRefresh else { return "Not refreshed yet" }
        return "Updated \(lastRefresh.formatted(date: .omitted, time: .shortened))"
    }

    static func mock() -> SpendStore {
        let calendar = Calendar.liteLLMUTC
        let now = Date()
        let today = calendar.startOfDay(for: now)

        let mockDailySpends: [Double] = [
            0.12, 0.08, 0.31, 0.00, 0.00, 0.45, 0.67, 0.23, 0.41, 0.55,
            0.34, 0.12, 0.00, 0.29, 0.87, 0.43, 0.21, 0.53, 0.78, 0.34,
            0.45, 0.12, 0.23, 0.34, 0.56, 0.78, 0.45, 0.34, 0.23, 1.847,
        ]
        let dailyPoints = (0..<30).map { i -> ChartPoint in
            let date = calendar.date(byAdding: .day, value: i - 29, to: today)!
            return ChartPoint(date: date, spend: mockDailySpends[i])
        }

        return SpendStore(mock: SpendSummary(
            todaySpend: 1.847,
            last7Spend: 9.312,
            monthSpend: 24.601,
            allTimeSpend: 87.443,
            cachedTokens: 1_240_000,
            totalTokens: 2_450_000,
            topModels: [
                ModelSpend(model: "claude-opus-4-5", spend: 0.923, requests: 47, tokens: 312_000, cachedTokens: 840_000),
                ModelSpend(model: "claude-sonnet-4-5", spend: 0.541, requests: 183, tokens: 620_000, cachedTokens: 400_000),
                ModelSpend(model: "gpt-4o", spend: 0.283, requests: 29, tokens: 88_000, cachedTokens: 0),
                ModelSpend(model: "gemini-2.0-flash", spend: 0.100, requests: 61, tokens: 145_000, cachedTokens: 0),
            ],
            dailyPoints: dailyPoints
        ))
    }

    private init(mock summary: SpendSummary) {
        self.defaults = .standard
        self.baseURLString = Self.defaultBaseURL
        self.refreshIntervalSeconds = 300
        self.currencyCode = "USD"
        self.summary = summary
        self.hasAPIKey = true
        self.loadState = .loaded
        self.lastRefresh = Date()
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.baseURLString = Self.normalizedBaseURL(
            defaults.string(forKey: DefaultsKey.baseURL) ?? Self.defaultBaseURL
        )
        let savedInterval = defaults.object(forKey: DefaultsKey.refreshIntervalSeconds) as? Int
        self.refreshIntervalSeconds = Self.clampedRefreshInterval(savedInterval ?? 300)
        self.currencyCode = Self.normalizedCurrencyCode(
            defaults.string(forKey: DefaultsKey.currencyCode) ?? "USD"
        )

        hasAPIKey = APIKeyStore.load() != nil
        loadState = hasAPIKey ? .idle : .needsConfiguration

        startWakeObserver()
        restartRefreshLoop()
    }

    deinit {
        refreshTask?.cancel()
        wakeTask?.cancel()
    }

    func refreshIfNeeded() async {
        guard hasAPIKey else { loadState = .needsConfiguration; return }
        guard lastRefresh == nil else { return }
        await refresh()
    }

    func refresh() async {
        guard !isRefreshing else { return }
        guard hasAPIKey else { loadState = .needsConfiguration; return }
        guard let baseURL = URL(string: baseURLString), baseURL.scheme != nil else {
            let error = ConfigurationError.invalidBaseURL
            loadState = .failed(error)
            bannerMessage = error.localizedDescription
            return
        }

        isRefreshing = true
        loadState = .loading
        defer { isRefreshing = false }

        let client = LiteLLMClient(baseURL: baseURL) { APIKeyStore.load() }

        do {
            let now = Date()
            let activity = try await client.fetchActivity(start: Self.allTimeStartDate, end: now)
            summary = SpendSummary(activity: activity, now: now)
            lastRefresh = Date()
            bannerMessage = nil
            loadState = .loaded

            if currencyCode == "EUR" {
                await fetchEURRate()
            }
        } catch LiteLLMClientError.unauthorized {
            handleUnauthorized()
        } catch {
            Logger.network.error("\(Logger.redacted(error.localizedDescription), privacy: .public)")
            bannerMessage = error.localizedDescription
            loadState = .failed(error)
        }
    }

    func refreshKeyAndConnect() async {
        hasAPIKey = APIKeyStore.load() != nil
        if hasAPIKey {
            bannerMessage = nil
            restartRefreshLoop()
        } else {
            loadState = .needsConfiguration
            bannerMessage = "No API key found. Set LITELLM_API_KEY or create \(APIKeyStore.configPath)."
        }
    }

    func updateConfiguration(baseURLString: String, refreshIntervalSeconds: Int, currencyCode: String) {
        self.baseURLString = Self.normalizedBaseURL(baseURLString)
        self.refreshIntervalSeconds = Self.clampedRefreshInterval(refreshIntervalSeconds)
        self.currencyCode = Self.normalizedCurrencyCode(currencyCode)

        defaults.set(self.baseURLString, forKey: DefaultsKey.baseURL)
        defaults.set(self.refreshIntervalSeconds, forKey: DefaultsKey.refreshIntervalSeconds)
        defaults.set(self.currencyCode, forKey: DefaultsKey.currencyCode)

        if hasAPIKey {
            restartRefreshLoop()
        }
    }

    func openDashboard(baseURLString override: String? = nil) {
        let urlString = Self.normalizedBaseURL(override ?? baseURLString)
        guard let baseURL = URL(string: urlString) else { return }
        NSWorkspace.shared.open(baseURL.appending(path: "ui"))
    }

    private func fetchEURRate() async {
        do {
            eurRate = try await exchangeRateService.fetchUSDtoEUR()
        } catch {
            Logger.network.warning("EUR rate fetch failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func restartRefreshLoop() {
        refreshTask?.cancel()
        refreshTask = nil

        guard hasAPIKey else { loadState = .needsConfiguration; return }

        let interval = Duration.seconds(max(5, refreshIntervalSeconds))
        refreshTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.refresh()
            while !Task.isCancelled {
                do { try await Task.sleep(for: interval) } catch { return }
                await self.refresh()
            }
        }
    }

    private func stopPolling() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    private func startWakeObserver() {
        wakeTask?.cancel()
        wakeTask = Task { @MainActor [weak self] in
            for await _ in NSWorkspace.shared.notificationCenter.notifications(named: NSWorkspace.didWakeNotification) {
                guard let self else { return }
                await self.refresh()
            }
        }
    }

    private func handleUnauthorized() {
        hasAPIKey = false
        bannerMessage = "API key invalid — check LITELLM_API_KEY or \(APIKeyStore.configPath)."
        loadState = .needsConfiguration
        stopPolling()
    }

    private static var allTimeStartDate: Date {
        var components = DateComponents()
        components.calendar = .liteLLMUTC
        components.timeZone = Calendar.liteLLMUTC.timeZone
        components.year = 2020
        components.month = 1
        components.day = 1
        return Calendar.liteLLMUTC.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }

    private static func normalizedBaseURL(_ value: String) -> String {
        var trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { trimmed = defaultBaseURL }
        if !trimmed.localizedCaseInsensitiveContains("://") { trimmed = "https://\(trimmed)" }
        while trimmed.last == "/" { trimmed.removeLast() }
        return trimmed
    }

    private static func clampedRefreshInterval(_ seconds: Int) -> Int {
        min(max(seconds, 5), 3600)
    }

    private static func normalizedCurrencyCode(_ value: String) -> String {
        let code = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let allowed = ["USD", "EUR"]
        return allowed.contains(code) ? code : "USD"
    }
}

private enum ConfigurationError: LocalizedError {
    case invalidBaseURL

    var errorDescription: String? { "Enter a valid LiteLLM base URL." }
}
