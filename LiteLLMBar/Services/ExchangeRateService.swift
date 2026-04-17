import Foundation

actor ExchangeRateService {
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        session = URLSession(configuration: config)
    }

    func fetchUSDtoEUR() async throws -> Double {
        let url = URL(string: "https://api.frankfurter.app/latest?from=USD&to=EUR")!
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        struct FrankfurterResponse: Decodable {
            let rates: [String: Double]
        }
        let decoded = try JSONDecoder().decode(FrankfurterResponse.self, from: data)
        return decoded.rates["EUR"] ?? 1.0
    }
}
