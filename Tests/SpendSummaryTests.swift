import Foundation
import Testing
@testable import LiteLLMBar

struct SpendSummaryTests {
    @Test
    func aggregatesRangesAndModels() throws {
        let json = """
        {
          "results": [
            {
              "date": "2026-04-11",
              "metrics": {
                "spend": 1.25,
                "prompt_tokens": 100,
                "completion_tokens": 50,
                "total_tokens": 150,
                "api_requests": 2,
                "cache_read_input_tokens": 1200,
                "cache_creation_input_tokens": 300
              },
              "breakdown": {
                "models": {
                  "gpt-5.4": {
                    "spend": 1.25,
                    "prompt_tokens": 100,
                    "completion_tokens": 50,
                    "total_tokens": 150,
                    "api_requests": 2,
                    "cache_read_input_tokens": 1200,
                    "cache_creation_input_tokens": 300
                  }
                }
              }
            },
            {
              "date": "2026-04-17",
              "metrics": {
                "spend": 0.50,
                "prompt_tokens": 25,
                "completion_tokens": 25,
                "total_tokens": 50,
                "api_requests": 1
              },
              "breakdown": {
                "models": {
                  "gpt-5.4-mini": {
                    "spend": 0.50,
                    "prompt_tokens": 25,
                    "completion_tokens": 25,
                    "total_tokens": 50,
                    "api_requests": 1
                  }
                }
              }
            }
          ],
          "metadata": {
            "total_spend": 1.75,
            "total_prompt_tokens": 125,
            "total_completion_tokens": 75,
            "total_api_requests": 3
          }
        }
        """

        let activity = try JSONDecoder().decode(DailyActivity.self, from: Data(json.utf8))
        let now = Calendar.liteLLMUTC.date(from: DateComponents(year: 2026, month: 4, day: 17))!
        let summary = SpendSummary(activity: activity, now: now)

        #expect(abs(summary.todaySpend - 0.50) < 0.0001)
        #expect(abs(summary.last7Spend - 1.75) < 0.0001)
        #expect(abs(summary.monthSpend - 1.75) < 0.0001)
        #expect(abs(summary.allTimeSpend - 1.75) < 0.0001)
        #expect(summary.cachedTokens == 1500)
        #expect(summary.topModels.first?.model == "gpt-5.4")
    }
}
