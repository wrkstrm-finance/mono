import WrkstrmNetworking

public struct AlpacaLatestStockQuoteURLRequest: AlpacaURLRequest {
  public typealias ResponseType = AlpacaLatestStockQuoteResponse

  public let service: AlpacaAPIService = .marketData
  public var method: HTTP.Method { .get }
  public let path: String
  public let options: HTTP.Request.Options

  public init(symbol: String, feed: String? = "iex") throws {
    path = "v2/stocks/\(try AlpacaClient.urlPathComponent(symbol))/quotes/latest"
    options = .make { q in
      q.add("feed", value: feed)
    }
  }
}
