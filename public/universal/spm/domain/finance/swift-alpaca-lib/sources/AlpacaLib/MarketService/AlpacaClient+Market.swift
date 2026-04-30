import Foundation

extension AlpacaClient {
  public func marketClock() async throws -> AlpacaClock {
    try await send(AlpacaMarketClockURLRequest())
  }

  public func marketCalendar(start: String? = nil, end: String? = nil) async throws -> [AlpacaCalendarDay] {
    try await send(AlpacaMarketCalendarURLRequest(start: start, end: end))
  }

  public func stockBars(
    symbol: String,
    timeframe: String,
    start: Date? = nil,
    end: Date? = nil,
    limit: Int? = nil,
    feed: String? = "iex"
  ) async throws -> [AlpacaBar] {
    let request = AlpacaStockBarsURLRequest(
      symbol: symbol,
      timeframe: timeframe,
      start: start,
      end: end,
      limit: limit,
      feed: feed
    )
    let response = try await send(request)
    return response.bars[symbol] ?? response.bars[symbol.uppercased()] ?? []
  }
}
