import Foundation
import WrkstrmNetworking

public struct AlpacaMarketClockURLRequest: AlpacaURLRequest {
  public typealias ResponseType = AlpacaClock

  public let service: AlpacaAPIService = .trading
  public var method: HTTP.Method { .get }
  public var path: String { "v2/clock" }

  public init() {}
}

public struct AlpacaMarketCalendarURLRequest: AlpacaURLRequest {
  public typealias ResponseType = [AlpacaCalendarDay]

  public let service: AlpacaAPIService = .trading
  public var method: HTTP.Method { .get }
  public var path: String { "v2/calendar" }
  public let options: HTTP.Request.Options

  public init(start: String? = nil, end: String? = nil) {
    options = .make { q in
      q.add("start", value: start)
      q.add("end", value: end)
    }
  }
}

public struct AlpacaStockBarsURLRequest: AlpacaURLRequest {
  public typealias ResponseType = AlpacaBarsResponse

  public let service: AlpacaAPIService = .marketData
  public var method: HTTP.Method { .get }
  public var path: String { "v2/stocks/bars" }
  public let options: HTTP.Request.Options

  public init(
    symbol: String,
    timeframe: String,
    start: Date? = nil,
    end: Date? = nil,
    limit: Int? = nil,
    feed: String? = "iex"
  ) {
    options = .make { q in
      q.add("symbols", value: symbol)
      q.add("timeframe", value: timeframe)
      q.add("start", value: start.map(AlpacaClient.formatDate))
      q.add("end", value: end.map(AlpacaClient.formatDate))
      q.add("limit", value: limit)
      q.add("feed", value: feed)
    }
  }
}
