import AlpacaLib
import CommonBroker
import Foundation

public struct AlpacaQuoteService: CommonQuoteService, CommonQuoteVariantService, Sendable {
  public nonisolated let serviceName = "Alpaca"
  public nonisolated let serviceType: ServiceType
  private let client: AlpacaClient
  private let feed: String?

  public init(client: AlpacaClient, feed: String? = "iex", serviceType: ServiceType = .production) {
    self.client = client
    self.feed = feed
    self.serviceType = serviceType
  }

  public func quote(for symbol: String, accountId _: String) async throws -> CommonQuoteVariant {
    try await quoteVariant(for: symbol, accountId: "", detail: .full)
  }

  public func quotes(for symbols: [String], accountId: String) async throws -> [CommonQuoteVariant] {
    try await quotesVariant(for: symbols, accountId: accountId, detail: .full)
  }

  public func quoteVariant(
    for symbol: String,
    accountId _: String,
    detail: QuoteDetail
  ) async throws -> CommonQuoteVariant {
    let quote = try await client.latestStockQuote(symbol: symbol, feed: feed)
    let detailed = commonQuote(symbol: symbol, quote: quote)
    switch detail {
    case .full:
      return .full(detailed)
    case .slim:
      return .slim(CommonBrokerageQuoteEssentialsModel(detailed))
    }
  }

  public func quotesVariant(
    for symbols: [String],
    accountId: String,
    detail: QuoteDetail
  ) async throws -> [CommonQuoteVariant] {
    try await withThrowingTaskGroup(of: (Int, CommonQuoteVariant).self) { group in
      for (index, symbol) in symbols.enumerated() {
        group.addTask {
          let quote = try await quoteVariant(for: symbol, accountId: accountId, detail: detail)
          return (index, quote)
        }
      }
      var result: [(Int, CommonQuoteVariant)] = []
      for try await value in group {
        result.append(value)
      }
      return result.sorted { $0.0 < $1.0 }.map(\.1)
    }
  }
}

func commonQuote(symbol: String, quote: AlpacaStockQuote) -> CommonBrokerageQuoteDetailedModel {
  CommonBrokerageQuoteDetailedModel(
    id: nil,
    assetType: "equity",
    tradeDate: quote.timestamp,
    symbol: symbol,
    symbolDescription: nil,
    exchange: nil,
    last: nil,
    change: nil,
    changePercentage: nil,
    bid: quote.bidPrice,
    bidSize: quote.bidSize,
    bidExchange: quote.bidExchange,
    bidDate: quote.timestamp,
    ask: quote.askPrice,
    askSize: quote.askSize,
    askExchange: quote.askExchange,
    askDate: quote.timestamp,
    open: nil,
    high: nil,
    low: nil,
    close: nil,
    volume: nil,
    previousClose: nil,
    fiftyTwoWeekHigh: nil,
    fiftyTwoWeekLow: nil,
    averageVolume: nil,
    latestTradeVolume: nil,
    rootSymbol: nil,
    underlying: nil,
    strikePrice: nil,
    openInterest: nil,
    contractSize: nil,
    expirationDate: nil,
    expirationStyle: nil,
    optionKind: nil,
    greeks: nil
  )
}
