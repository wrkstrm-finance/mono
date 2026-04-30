import AlpacaLib
import CommonBroker
import Foundation

public struct AlpacaOptionQuoteService: CommonOptionQuoteService, Sendable {
  public nonisolated let serviceName = "Alpaca"
  public nonisolated let serviceType: ServiceType
  private let client: AlpacaClient
  private let feed: String?

  public init(client: AlpacaClient, feed: String? = "indicative", serviceType: ServiceType = .sandbox) {
    self.client = client
    self.feed = feed
    self.serviceType = serviceType
  }

  public func optionQuote(for symbol: String, accountId _: String) async throws -> CommonBrokerageOptionQuoteModel {
    let response = try await client.optionSnapshots(symbols: [symbol], feed: feed)
    guard let snapshot = response.snapshots[symbol] ?? response.snapshots[symbol.uppercased()] else {
      throw AlpacaCommonAdapterError.missingData("No Alpaca option snapshot for \(symbol).")
    }
    return commonOptionQuote(symbol: symbol, snapshot: snapshot)
  }
}

public struct AlpacaOptionService: CommonOptionService, Sendable {
  public nonisolated let serviceName = "Alpaca"
  public nonisolated let serviceType: ServiceType
  private let client: AlpacaClient
  private let feed: String?

  public init(client: AlpacaClient, feed: String? = "indicative", serviceType: ServiceType = .sandbox) {
    self.client = client
    self.feed = feed
    self.serviceType = serviceType
  }

  public func expirations(for symbol: String) async throws -> [CommonBrokerageOptionExpirationModel] {
    let today = alpacaDateString(Date())
    let response = try await client.optionContracts(
      underlyingSymbols: [symbol],
      expirationDateGte: today
    )
    let grouped = Dictionary(grouping: response.optionContracts) { contract in
      contract.expirationDate.map(alpacaDateString) ?? ""
    }
    return grouped.compactMap { dateString, contracts in
      guard dateString.isEmpty == false, let date = contracts.first?.expirationDate else {
        return nil
      }
      let strikes = contracts.compactMap { double($0.strikePrice) }.sorted()
      return CommonBrokerageOptionExpirationModel(
        date: date,
        dateString: dateString,
        expirationType: "standard",
        strikes: Array(Set(strikes)).sorted()
      )
    }.sorted { $0.date < $1.date }
  }

  public func optionQuotes(
    for symbol: String,
    expiration: CommonBrokerageOptionExpirationModel,
    kind: CommonOptionKind,
    maxStrikes: Int,
    includeGreeks _: Bool
  ) async throws -> [CommonBrokerageOptionQuoteModel] {
    let response = try await client.optionChainSnapshots(
      underlyingSymbol: symbol,
      feed: feed,
      expirationDate: expiration.dateString,
      type: kind.alpacaType,
      limit: max(1, min(maxStrikes, 1_000))
    )
    return response.snapshots
      .map { commonOptionQuote(symbol: $0.key, snapshot: $0.value) }
      .sorted { ($0.strikePrice ?? 0, $0.symbol) < ($1.strikePrice ?? 0, $1.symbol) }
  }

  public func optionChain(
    for symbol: String,
    expiration: CommonBrokerageOptionExpirationModel,
    includeGreeks _: Bool
  ) async throws -> [CommonBrokerageOptionQuoteModel] {
    let response = try await client.optionChainSnapshots(
      underlyingSymbol: symbol,
      feed: feed,
      expirationDate: expiration.dateString
    )
    return response.snapshots
      .map { commonOptionQuote(symbol: $0.key, snapshot: $0.value) }
      .sorted { ($0.strikePrice ?? 0, $0.symbol) < ($1.strikePrice ?? 0, $1.symbol) }
  }
}

func commonOptionQuote(symbol: String, snapshot: AlpacaOptionSnapshot) -> CommonBrokerageOptionQuoteModel {
  let parsed = OSISymbolParser.parse(symbol)
  return CommonBrokerageOptionQuoteModel(
    symbol: symbol,
    underlying: parsed.root,
    last: snapshot.latestTrade?.price,
    bid: snapshot.latestQuote?.bidPrice,
    ask: snapshot.latestQuote?.askPrice,
    strikePrice: parsed.strike,
    expirationDate: parsed.expiration,
    optionKind: parsed.optionKind,
    greeks: commonOptionGreeks(snapshot: snapshot)
  )
}

func commonOptionGreeks(snapshot: AlpacaOptionSnapshot) -> CommonBrokerageOptionGreeksModel? {
  guard snapshot.greeks != nil || snapshot.impliedVolatility != nil else {
    return nil
  }
  return CommonBrokerageOptionGreeksModel(
    delta: snapshot.greeks?.delta,
    gamma: snapshot.greeks?.gamma,
    theta: snapshot.greeks?.theta,
    vega: snapshot.greeks?.vega,
    rho: snapshot.greeks?.rho,
    impliedVolatility: snapshot.impliedVolatility,
    bidImpliedVolatility: nil,
    midImpliedVolatility: snapshot.impliedVolatility,
    askImpliedVolatility: nil,
    updatedAt: snapshot.latestQuote?.timestamp ?? snapshot.latestTrade?.timestamp
  )
}

extension CommonOptionKind {
  var alpacaType: String {
    switch self {
    case .call:
      "call"
    case .put:
      "put"
    }
  }
}
