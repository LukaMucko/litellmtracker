import Foundation

struct DailyActivity: Decodable, Sendable {
    let results: [DailyResult]
    let metadata: Metadata

    struct Metadata: Decodable, Sendable {
        let total_spend: Double
        let total_prompt_tokens: Int
        let total_completion_tokens: Int
        let total_api_requests: Int
        let has_more: Bool

        enum CodingKeys: String, CodingKey {
            case total_spend
            case total_prompt_tokens
            case total_completion_tokens
            case total_api_requests
            case has_more
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            total_spend = try container.decodeLossyDouble(forKey: .total_spend)
            total_prompt_tokens = try container.decodeLossyInt(forKey: .total_prompt_tokens)
            total_completion_tokens = try container.decodeLossyInt(forKey: .total_completion_tokens)
            total_api_requests = try container.decodeLossyInt(forKey: .total_api_requests)
            has_more = try container.decodeIfPresent(Bool.self, forKey: .has_more) ?? false
        }

        static let empty = Metadata(
            total_spend: 0,
            total_prompt_tokens: 0,
            total_completion_tokens: 0,
            total_api_requests: 0,
            has_more: false
        )

        init(total_spend: Double, total_prompt_tokens: Int, total_completion_tokens: Int, total_api_requests: Int, has_more: Bool = false) {
            self.total_spend = total_spend
            self.total_prompt_tokens = total_prompt_tokens
            self.total_completion_tokens = total_completion_tokens
            self.total_api_requests = total_api_requests
            self.has_more = has_more
        }
    }

    enum CodingKeys: String, CodingKey {
        case results
        case metadata
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        results = try container.decodeIfPresent([DailyResult].self, forKey: .results) ?? []
        metadata = try container.decodeIfPresent(Metadata.self, forKey: .metadata) ?? .empty
    }

    init(results: [DailyResult], metadata: Metadata) {
        self.results = results
        self.metadata = metadata
    }
}

struct DailyResult: Decodable, Sendable {
    let date: String
    let metrics: Metrics
    let breakdown: Breakdown

    struct Metrics: Decodable, Sendable {
        let spend: Double
        let prompt_tokens: Int
        let completion_tokens: Int
        let total_tokens: Int
        let api_requests: Int
        let cache_read_input_tokens: Int?
        let cache_creation_input_tokens: Int?

        var cachedTokens: Int {
            (cache_read_input_tokens ?? 0) + (cache_creation_input_tokens ?? 0)
        }

        enum CodingKeys: String, CodingKey {
            case spend
            case prompt_tokens
            case completion_tokens
            case total_tokens
            case api_requests
            case cache_read_input_tokens
            case cache_creation_input_tokens
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            spend = try container.decodeLossyDouble(forKey: .spend)
            prompt_tokens = try container.decodeLossyInt(forKey: .prompt_tokens)
            completion_tokens = try container.decodeLossyInt(forKey: .completion_tokens)
            total_tokens = try container.decodeLossyInt(forKey: .total_tokens)
            api_requests = try container.decodeLossyInt(forKey: .api_requests)
            cache_read_input_tokens = try container.decodeLossyOptionalInt(forKey: .cache_read_input_tokens)
            cache_creation_input_tokens = try container.decodeLossyOptionalInt(forKey: .cache_creation_input_tokens)
        }
    }

    struct Breakdown: Decodable, Sendable {
        let models: [String: ModelBreakdownEntry]

        enum CodingKeys: String, CodingKey {
            case models
        }

        static let empty = Breakdown(models: [:])

        init(models: [String: ModelBreakdownEntry]) {
            self.models = models
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            models = try container.decodeIfPresent([String: ModelBreakdownEntry].self, forKey: .models) ?? [:]
        }
    }

    // API response: { "metrics": {...}, "metadata": {}, "api_key_breakdown": {...} }
    struct ModelBreakdownEntry: Decodable, Sendable {
        let metrics: ModelMetrics

        enum CodingKeys: String, CodingKey { case metrics }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            metrics = try container.decode(ModelMetrics.self, forKey: .metrics)
        }
    }

    struct ModelMetrics: Decodable, Sendable {
        let spend: Double
        let prompt_tokens: Int
        let completion_tokens: Int
        let total_tokens: Int
        let api_requests: Int
        let cache_read_input_tokens: Int?
        let cache_creation_input_tokens: Int?

        var cachedTokens: Int {
            (cache_read_input_tokens ?? 0) + (cache_creation_input_tokens ?? 0)
        }

        enum CodingKeys: String, CodingKey {
            case spend
            case prompt_tokens
            case completion_tokens
            case total_tokens
            case api_requests
            case cache_read_input_tokens
            case cache_creation_input_tokens
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            spend = try container.decodeLossyDouble(forKey: .spend)
            prompt_tokens = try container.decodeLossyInt(forKey: .prompt_tokens)
            completion_tokens = try container.decodeLossyInt(forKey: .completion_tokens)
            total_tokens = try container.decodeLossyInt(forKey: .total_tokens)
            api_requests = try container.decodeLossyInt(forKey: .api_requests)
            cache_read_input_tokens = try container.decodeLossyOptionalInt(forKey: .cache_read_input_tokens)
            cache_creation_input_tokens = try container.decodeLossyOptionalInt(forKey: .cache_creation_input_tokens)
        }
    }

    enum CodingKeys: String, CodingKey {
        case date
        case metrics
        case breakdown
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decodeIfPresent(String.self, forKey: .date) ?? ""
        metrics = try container.decode(Metrics.self, forKey: .metrics)
        breakdown = try container.decodeIfPresent(Breakdown.self, forKey: .breakdown) ?? .empty
    }
}

private extension KeyedDecodingContainer {
    func decodeLossyDouble(forKey key: Key) throws -> Double {
        do {
            if let value = try decodeIfPresent(Double.self, forKey: key) {
                return value
            }
        } catch {
            // Try the other wire formats below.
        }
        do {
            if let value = try decodeIfPresent(Int.self, forKey: key) {
                return Double(value)
            }
        } catch {
            // Try the other wire formats below.
        }
        do {
            if let value = try decodeIfPresent(String.self, forKey: key), let number = Double(value) {
                return number
            }
        } catch {
            // Fall through to the default.
        }
        return 0
    }

    func decodeLossyInt(forKey key: Key) throws -> Int {
        do {
            if let value = try decodeIfPresent(Int.self, forKey: key) {
                return value
            }
        } catch {
            // Try the other wire formats below.
        }
        do {
            if let value = try decodeIfPresent(Double.self, forKey: key) {
                return Int(value)
            }
        } catch {
            // Try the other wire formats below.
        }
        do {
            if let value = try decodeIfPresent(String.self, forKey: key), let number = Int(value) {
                return number
            }
        } catch {
            // Fall through to the default.
        }
        return 0
    }

    func decodeLossyOptionalInt(forKey key: Key) throws -> Int? {
        guard contains(key) else { return nil }
        do {
            if let value = try decodeIfPresent(Int.self, forKey: key) {
                return value
            }
        } catch {
            // Try the other wire formats below.
        }
        do {
            if let value = try decodeIfPresent(Double.self, forKey: key) {
                return Int(value)
            }
        } catch {
            // Try the other wire formats below.
        }
        do {
            if let value = try decodeIfPresent(String.self, forKey: key) {
                return Int(value)
            }
        } catch {
            // Fall through to nil.
        }
        return nil
    }
}
