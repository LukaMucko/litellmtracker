import Foundation
import Testing
@testable import LiteLLMBar

struct LiteLLMClientTests {
    @Test
    func dailyActivityDecodeToleratesMissingOptionalBreakdowns() throws {
        let json = """
        {
          "results": [
            {
              "date": "2026-04-17",
              "metrics": {
                "spend": "0.47",
                "prompt_tokens": 10,
                "completion_tokens": 5,
                "total_tokens": 15,
                "api_requests": 1,
                "cache_read_input_tokens": 19700000
              },
              "breakdown": {
                "models": {}
              }
            }
          ],
          "metadata": {
            "total_spend": "0.47",
            "total_prompt_tokens": 10,
            "total_completion_tokens": 5,
            "total_api_requests": 1
          }
        }
        """

        let activity = try JSONDecoder().decode(DailyActivity.self, from: Data(json.utf8))

        #expect(activity.results.count == 1)
        #expect(abs(activity.results[0].metrics.spend - 0.47) < 0.0001)
        #expect(activity.results[0].metrics.cachedTokens == 19_700_000)
        #expect(activity.results[0].breakdown.models.isEmpty)
    }
}
