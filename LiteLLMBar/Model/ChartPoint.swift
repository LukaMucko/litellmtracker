import Foundation

struct ChartPoint: Identifiable, Equatable, Sendable {
    let id: UUID
    let date: Date
    let spend: Double

    init(date: Date, spend: Double) {
        id = UUID()
        self.date = date
        self.spend = spend
    }
}

enum ChartRange: String, CaseIterable, Identifiable {
    case week = "7D"
    case month = "30D"

    var id: String { rawValue }
}
