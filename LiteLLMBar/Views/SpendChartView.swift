import Charts
import SwiftUI

struct SpendChartView: View {
    let summary: SpendSummary
    let currencyCode: String
    let eurRate: Double

    @State private var selectedRange: ChartRange = .week
    @State private var selectedX: Date?

    private var points: [ChartPoint] {
        switch selectedRange {
        case .week:  summary.last7Points
        case .month: summary.last30Points
        }
    }

    private var selectedPoint: ChartPoint? {
        guard let x = selectedX else { return nil }
        return points.min(by: { abs($0.date.timeIntervalSince(x)) < abs($1.date.timeIntervalSince(x)) })
    }

    private func displaySpend(_ usd: Double) -> Double {
        currencyCode == "EUR" ? usd * eurRate : usd
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Activity")
                    .font(.headline)
                Spacer()
                Picker(selection: $selectedRange) {
                    ForEach(ChartRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                } label: {
                    EmptyView()
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }

            chartBody
                .id(selectedRange)
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
                .animation(.spring(duration: 0.35, bounce: 0), value: selectedRange)
        }
        .padding(16)
        .spendGlassCard(cornerRadius: 16)
    }

    private var yMax: Double {
        max((points.map { displaySpend($0.spend) }.max() ?? 0) * 1.2, 0.001)
    }

    private var areaGradient: LinearGradient {
        LinearGradient(
            colors: [Color.accentColor.opacity(0.4), Color.accentColor.opacity(0.0)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var chartBody: some View {
        Chart {
            ForEach(points) { pt in
                AreaMark(
                    x: .value("Date", pt.date),
                    y: .value("Spend", displaySpend(pt.spend))
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(areaGradient)

                LineMark(
                    x: .value("Date", pt.date),
                    y: .value("Spend", displaySpend(pt.spend))
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.accentColor)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }

            if let sp = selectedPoint {
                RuleMark(x: .value("Selected", sp.date))
                    .foregroundStyle(.secondary.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 2]))
                    .annotation(
                        position: annotationPosition(for: sp),
                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                    ) {
                        tooltipView(for: sp)
                    }
            }
        }
        .chartXSelection(value: $selectedX)
        .chartYScale(domain: 0...yMax)
        .chartYAxis {
            AxisMarks(preset: .aligned, values: .automatic(desiredCount: 3)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(CurrencyFormatter.compactAmount(amount, currencyCode: currencyCode))
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: xAxisValues) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(xAxisLabel(for: date))
                            .font(.caption2)
                    }
                }
            }
        }
        .frame(height: 120)
    }

    private func tooltipView(for point: ChartPoint) -> some View {
        VStack(spacing: 2) {
            Text(CurrencyFormatter.string(displaySpend(point.spend), currencyCode: currencyCode))
                .font(.caption)
                .fontWeight(.semibold)
                .monospacedDigit()
            Text(dateLabel(for: point.date))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
    }

    private func annotationPosition(for point: ChartPoint) -> AnnotationPosition {
        guard points.count > 1,
              let idx = points.firstIndex(where: { $0.id == point.id })
        else { return .top }
        return idx >= points.count * 3 / 4 ? .topLeading : .topTrailing
    }

    private func dateLabel(for date: Date) -> String {
        let f = DateFormatter()
        switch selectedRange {
        case .week:  f.dateFormat = "EEE d MMM"
        case .month: f.dateFormat = "d MMM"
        }
        return f.string(from: date)
    }

    private var xAxisValues: AxisMarkValues {
        switch selectedRange {
        case .week:  .stride(by: .day, count: 1)
        case .month: .stride(by: .day, count: 7)
        }
    }

    private func xAxisLabel(for date: Date) -> String {
        let f = DateFormatter()
        switch selectedRange {
        case .week:  f.dateFormat = "EEE"
        case .month: f.dateFormat = "d MMM"
        }
        return f.string(from: date)
    }
}

#Preview {
    let store = SpendStore.mock()
    SpendChartView(
        summary: store.summary,
        currencyCode: "USD",
        eurRate: 1.0
    )
    .frame(width: 340)
    .padding(20)
}
