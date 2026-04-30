import AlpacaLib
import CommonBroker
import Foundation

public struct AlpacaMarketService: CommonMarketService, Sendable {
  public nonisolated let serviceName = "Alpaca"
  public nonisolated let serviceType: ServiceType
  private let client: AlpacaClient
  private let feed: String?

  public init(client: AlpacaClient, feed: String? = "iex", serviceType: ServiceType = .sandbox) {
    self.client = client
    self.feed = feed
    self.serviceType = serviceType
  }

  public func clock() async throws -> CommonBrokerageMarketClockModel {
    let clock = try await client.marketClock()
    let state: CommonMarketState = clock.isOpen ? .open : .closed
    let nextState: CommonMarketState = clock.isOpen ? .closed : .open
    let nextChange = clock.isOpen ? clock.nextClose : clock.nextOpen
    return CommonBrokerageMarketClockModel(
      date: alpacaDateString(clock.timestamp),
      description: clock.isOpen ? "Alpaca market is open" : "Alpaca market is closed",
      state: state,
      timestamp: unixSeconds(clock.timestamp),
      nextChange: alpacaDateTimeString(nextChange),
      nextState: nextState
    )
  }

  public func calendar(month: Int, year: Int) async throws -> [CommonBrokerageMarketDayModel] {
    let range = monthDateRange(month: month, year: year)
    let days = try await client.marketCalendar(
      start: alpacaDateString(range.start),
      end: alpacaDateString(range.end)
    )
    return days.compactMap(commonMarketDay)
  }

  public func timeSales(symbol: String, interval: CommonInterval) async throws -> [CommonBrokerageTimeSaleModel] {
    try await client.stockBars(
      symbol: symbol,
      timeframe: interval.alpacaTimeframe,
      limit: 1_000,
      feed: feed
    ).map { bar in
      CommonBrokerageTimeSaleModel(
        time: bar.timestamp,
        timestamp: unixSeconds(bar.timestamp),
        price: bar.close,
        open: bar.open,
        high: bar.high,
        low: bar.low,
        close: bar.close,
        volume: bar.volume,
        vwap: bar.vwap ?? bar.close
      )
    }
  }
}

func commonMarketDay(_ day: AlpacaCalendarDay) -> CommonBrokerageMarketDayModel? {
  guard let date = alpacaDate(day.date) else { return nil }
  let openTime = day.open ?? day.sessionOpen
  let closeTime = day.close ?? day.sessionClose
  let open = openTime.flatMap { alpacaMarketSession(date: day.date, open: $0, close: closeTime) }
  return CommonBrokerageMarketDayModel(
    date: date,
    status: "open",
    description: day.settlementDate.map { "Settlement date: \($0)" },
    premarket: nil,
    open: open,
    postmarket: nil
  )
}

func alpacaMarketSession(date: String, open: String, close: String?) -> CommonBrokerageMarketSessionModel? {
  guard
    let close,
    let start = alpacaDateTime(date: date, time: open),
    let end = alpacaDateTime(date: date, time: close)
  else {
    return nil
  }
  return CommonBrokerageMarketSessionModel(start: start, end: end)
}

extension CommonInterval {
  var alpacaTimeframe: String {
    switch self {
    case .tick:
      "1Min"
    case .oneMin:
      "1Min"
    case .fiveMin:
      "5Min"
    }
  }
}
