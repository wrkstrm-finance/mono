import Foundation
import MarketSummarizer
import Testing

@Suite struct MarketSummarizerBasicTests {
  @Test func rendersText() async throws {
    let engine = MarketSummarizerEngine()
    let s = engine.summarize(symbols: ["AAPL", "NVDA"])
    let text = engine.render(s, as: .text)
    #expect(text.contains("EOD Summary"))
    #expect(text.contains("AAPL"))
    #expect(text.contains("NVDA"))
  }
}
