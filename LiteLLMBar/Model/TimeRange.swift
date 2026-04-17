import Foundation

enum TimeRange: String, CaseIterable, Identifiable, Sendable {
    case today
    case last7Days
    case month
    case allTime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today:
            "Today"
        case .last7Days:
            "7 days"
        case .month:
            "Month"
        case .allTime:
            "All time"
        }
    }
}
