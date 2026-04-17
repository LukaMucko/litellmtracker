import Foundation

enum CurrencyFormatter {
    static func string(_ amount: Double, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = amount >= 100 ? 0 : 2
        formatter.minimumFractionDigits = amount >= 100 ? 0 : 2

        return formatter.string(from: NSNumber(value: amount)) ?? "\(currencyCode) \(String(format: "%.2f", amount))"
    }

    static func compactAmount(_ value: Double, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = value >= 1 ? 2 : 3
        return formatter.string(from: NSNumber(value: value))
            ?? "\(currencyCode == "EUR" ? "€" : "$")\(String(format: "%.2f", value))"
    }

    static func compactCount(_ value: Int) -> String {
        let absolute = Double(abs(value))
        let sign = value < 0 ? "-" : ""

        switch absolute {
        case 1_000_000_000...:
            return "\(sign)\(format(absolute / 1_000_000_000))B"
        case 1_000_000...:
            return "\(sign)\(format(absolute / 1_000_000))M"
        case 1_000...:
            return "\(sign)\(format(absolute / 1_000))K"
        default:
            return "\(value)"
        }
    }

    private static func format(_ value: Double) -> String {
        value >= 10 ? String(format: "%.0f", value) : String(format: "%.1f", value)
    }
}
