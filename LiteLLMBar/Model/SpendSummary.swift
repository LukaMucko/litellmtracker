import Foundation

struct SpendSummary: Equatable, Sendable {
    let todaySpend: Double
    let last7Spend: Double
    let monthSpend: Double
    let allTimeSpend: Double
    let cachedTokens: Int
    let totalTokens: Int
    let topModels: [ModelSpend]
    let dailyPoints: [ChartPoint]   // last 30 days, zero-filled, USD

    var last7Points: [ChartPoint] { Array(dailyPoints.suffix(7)) }
    var last30Points: [ChartPoint] { dailyPoints }

    static let empty = SpendSummary(
        todaySpend: 0, last7Spend: 0, monthSpend: 0, allTimeSpend: 0,
        cachedTokens: 0, totalTokens: 0, topModels: [], dailyPoints: []
    )

    init(
        todaySpend: Double,
        last7Spend: Double,
        monthSpend: Double,
        allTimeSpend: Double,
        cachedTokens: Int,
        totalTokens: Int,
        topModels: [ModelSpend],
        dailyPoints: [ChartPoint]
    ) {
        self.todaySpend = todaySpend
        self.last7Spend = last7Spend
        self.monthSpend = monthSpend
        self.allTimeSpend = allTimeSpend
        self.cachedTokens = cachedTokens
        self.totalTokens = totalTokens
        self.topModels = topModels
        self.dailyPoints = dailyPoints
    }

    init(activity: DailyActivity, now: Date = Date(), calendar: Calendar = .liteLLMUTC) {
        let today = calendar.startOfDay(for: now)
        let last7Start = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today

        var todaySpend = 0.0
        var last7Spend = 0.0
        var monthSpend = 0.0
        var allTimeSpend = 0.0
        var cachedTokens = 0
        var totalTokens = 0
        var dailySpend: [Date: Double] = [:]
        var models: [String: ModelAccumulator] = [:]

        for result in activity.results {
            guard let date = Self.date(from: result.date, calendar: calendar) else { continue }

            allTimeSpend += result.metrics.spend
            cachedTokens += result.metrics.cachedTokens
            totalTokens += result.metrics.total_tokens
            dailySpend[date, default: 0] += result.metrics.spend

            if calendar.isDate(date, inSameDayAs: today) {
                todaySpend += result.metrics.spend
            }
            if date >= last7Start && date <= today {
                last7Spend += result.metrics.spend
            }
            if date >= monthStart && date <= today {
                monthSpend += result.metrics.spend
            }

            for (model, entry) in result.breakdown.models {
                models[model, default: ModelAccumulator()].add(entry.metrics)
            }
        }

        let topModels = models
            .map { model, acc in
                ModelSpend(model: model, spend: acc.spend, requests: acc.requests,
                           tokens: acc.tokens, cachedTokens: acc.cachedTokens)
            }
            .filter { $0.spend > 0 }
            .sorted { $0.spend > $1.spend }
            .prefix(6)

        var daily: [ChartPoint] = []
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: i - 29, to: today) ?? today
            daily.append(ChartPoint(date: date, spend: dailySpend[date] ?? 0))
        }

        self.init(
            todaySpend: todaySpend,
            last7Spend: last7Spend,
            monthSpend: monthSpend,
            allTimeSpend: allTimeSpend,
            cachedTokens: cachedTokens,
            totalTokens: totalTokens,
            topModels: Array(topModels),
            dailyPoints: daily
        )
    }

    private static func date(from string: String, calendar: Calendar) -> Date? {
        let parts = string.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        return calendar.date(from: components)
    }
}

private struct ModelAccumulator: Sendable {
    var spend = 0.0
    var requests = 0
    var tokens = 0
    var cachedTokens = 0

    mutating func add(_ metrics: DailyResult.ModelMetrics) {
        spend += metrics.spend
        requests += metrics.api_requests
        tokens += metrics.total_tokens
        cachedTokens += metrics.cachedTokens
    }
}

extension Calendar {
    static var liteLLMUTC: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }
}
