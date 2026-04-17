import Foundation

struct ModelSpend: Identifiable, Equatable, Sendable {
    let model: String
    let spend: Double
    let requests: Int
    let tokens: Int
    let cachedTokens: Int

    var id: String { model }
}
