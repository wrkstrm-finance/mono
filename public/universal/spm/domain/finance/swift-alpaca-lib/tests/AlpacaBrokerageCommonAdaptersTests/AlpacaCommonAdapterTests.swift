@preconcurrency import Foundation
import Testing
import WrkstrmNetworking

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import AlpacaBrokerageCommonAdapters
import AlpacaLib
import CommonBroker

@Test
func quoteAdapterMapsLatestQuoteToCommonVariant() async throws {
  let client = AlpacaClient(
    credentials: .init(apiKeyID: "key-id", secretKey: "secret"),
    environment: .custom(
      tradingBaseURL: URL(string: "https://paper.example.test")!,
      dataBaseURL: URL(string: "https://data.example.test")!
    ),
    transport: StubHTTPClient(
      body: try fixture(named: "latest_stock_quote")
    )
  )
  let service = AlpacaQuoteService(client: client)

  let variant = try await service.quoteVariant(for: "GOOG", accountId: "", detail: .full)

  switch variant {
  case .full(let detailed):
    #expect(detailed.symbol == "GOOG")
    #expect(detailed.bid == 342.31)
    #expect(detailed.ask == 342.35)
  case .slim:
    Issue.record("Expected a full quote variant.")
  }
}

@Test
func positionsAdapterMapsOpenPositions() async throws {
  let client = AlpacaClient(
    credentials: .init(apiKeyID: "key-id", secretKey: "secret"),
    environment: .custom(
      tradingBaseURL: URL(string: "https://paper.example.test")!,
      dataBaseURL: URL(string: "https://data.example.test")!
    ),
    transport: StubHTTPClient(
      body: try fixture(named: "open_positions")
    )
  )
  let service = AlpacaPositionsService(client: client)

  let positions = try await service.positions(for: "acct-1")
  let position = try #require(positions.first)

  #expect(position.symbol == "GOOG")
  #expect(position.quantity == 2)
  #expect(position.costBasis == 601)
  #expect(position.marketValue == 684.64)
  #expect(position.accountId == "acct-1")
}

@Test
func orderAdapterKeepsAlpacaIDAsPartnerID() async throws {
  let client = AlpacaClient(
    credentials: .init(apiKeyID: "key-id", secretKey: "secret"),
    environment: .custom(
      tradingBaseURL: URL(string: "https://paper.example.test")!,
      dataBaseURL: URL(string: "https://data.example.test")!
    ),
    transport: StubHTTPClient(
      body: try fixture(named: "place_order_response")
    )
  )
  let service = AlpacaOrderService(client: client)

  let result = try await service.placeOrder(
    accountId: "acct-1",
    symbol: "GOOG",
    side: .buy,
    quantity: 1,
    type: .limit,
    duration: .day,
    price: 342.32
  )

  #expect(result.status == "accepted")
  #expect(result.partnerId == "9f6d8f4c-b0d4-4b4d-a9b0-6d83a41d2f39")
}

@Test
func secretAdapterStoresPaperCredentialsBlob() async throws {
  let service = AlpacaSecretService()
  let secret = Data("paper-key:paper-secret".utf8)

  try await service.storeSecret(secret, for: .alpaca)
  let stored = try await service.secret(for: .alpaca)

  #expect(stored == secret)
}

@Test
func marketAdapterMapsClock() async throws {
  let client = AlpacaClient(
    credentials: .init(apiKeyID: "key-id", secretKey: "secret"),
    environment: .custom(
      tradingBaseURL: URL(string: "https://paper.example.test")!,
      dataBaseURL: URL(string: "https://data.example.test")!
    ),
    transport: StubHTTPClient(
      body: try fixture(named: "market_clock")
    )
  )
  let service = AlpacaMarketService(client: client)

  let clock = try await service.clock()

  #expect(clock.state == .open)
  #expect(clock.nextState == .closed)
  #expect(clock.date == "2026-04-24")
}

@Test
func activityAdapterMapsHistoryAndDerivedGainLoss() async throws {
  let client = AlpacaClient(
    credentials: .init(apiKeyID: "key-id", secretKey: "secret"),
    environment: .custom(
      tradingBaseURL: URL(string: "https://paper.example.test")!,
      dataBaseURL: URL(string: "https://data.example.test")!
    ),
    transport: StubHTTPClient(body: try fixture(named: "account_fills"))
  )
  let service = AlpacaActivityService(client: client)

  let history = try await service.history(for: "acct-1", start: nil, end: nil, type: .trade)
  let closed = try await service.gainLoss(
    for: "acct-1",
    page: nil,
    limit: nil,
    sortBy: nil,
    sort: nil,
    start: nil,
    end: nil,
    symbol: "GOOG"
  )

  #expect(history.count == 2)
  #expect(history.first?.trade?.symbol == "GOOG")
  #expect(closed.first?.realizedPnl == 10)
}

@Test
func referenceAdapterFiltersActiveAssets() async throws {
  let client = AlpacaClient(
    credentials: .init(apiKeyID: "key-id", secretKey: "secret"),
    environment: .custom(
      tradingBaseURL: URL(string: "https://paper.example.test")!,
      dataBaseURL: URL(string: "https://data.example.test")!
    ),
    transport: StubHTTPClient(
      body: try fixture(named: "assets")
    )
  )
  let service = AlpacaReferenceService(client: client)

  let symbols = try await service.searchSymbols("alpha")

  #expect(symbols.map(\.symbol) == ["GOOG"])
  #expect(symbols.first?.name == "Alphabet Inc.")
}

@Test
func watchlistAdapterMapsAssets() async throws {
  let client = AlpacaClient(
    credentials: .init(apiKeyID: "key-id", secretKey: "secret"),
    environment: .custom(
      tradingBaseURL: URL(string: "https://paper.example.test")!,
      dataBaseURL: URL(string: "https://data.example.test")!
    ),
    transport: StubHTTPClient(
      body: try fixture(named: "watchlists")
    )
  )
  let service = AlpacaWatchlistService(client: client)

  let watchlists = try await service.watchlists()
  let watchlist = try #require(watchlists.first)

  #expect(watchlist.id == "watchlist-1")
  #expect(watchlist.items.first?.symbol == "GOOG")
}

@Test
func optionQuoteAdapterMapsSnapshotGreeks() async throws {
  let client = AlpacaClient(
    credentials: .init(apiKeyID: "key-id", secretKey: "secret"),
    environment: .custom(
      tradingBaseURL: URL(string: "https://paper.example.test")!,
      dataBaseURL: URL(string: "https://data.example.test")!
    ),
    transport: StubHTTPClient(
      body: try fixture(named: "option_snapshot")
    )
  )
  let service = AlpacaOptionQuoteService(client: client)

  let quote = try await service.optionQuote(for: "AAPL260116C00195000", accountId: "acct-1")

  #expect(quote.underlying == "AAPL")
  #expect(quote.bid == 12.3)
  #expect(quote.ask == 12.5)
  #expect(quote.last == 12.4)
  #expect(quote.greeks?.delta == 0.5)
  #expect(quote.greeks?.impliedVolatility == 0.24)
}

@Test
func optionServiceMapsExpirationsFromContracts() async throws {
  let client = AlpacaClient(
    credentials: .init(apiKeyID: "key-id", secretKey: "secret"),
    environment: .custom(
      tradingBaseURL: URL(string: "https://paper.example.test")!,
      dataBaseURL: URL(string: "https://data.example.test")!
    ),
    transport: StubHTTPClient(
      body: try fixture(named: "option_contracts")
    )
  )
  let service = AlpacaOptionService(client: client)

  let expirations = try await service.expirations(for: "AAPL")
  let expiration = try #require(expirations.first)

  #expect(expiration.dateString == "2026-01-16")
  #expect(expiration.strikes == [190, 195])
}

private func fixture(named name: String) throws -> String {
  guard let url = Bundle.module.url(forResource: name, withExtension: "json") else {
    throw URLError(.fileDoesNotExist)
  }
  return try String(contentsOf: url, encoding: .utf8)
}

private actor StubHTTPClient: HTTP.Transport {
  private let body: Data

  init(body: String) {
    self.body = Data(body.utf8)
  }

  func execute(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
    let response = HTTPURLResponse(
      url: request.url ?? URL(string: "https://example.test")!,
      statusCode: 200,
      httpVersion: nil,
      headerFields: nil
    )!
    return (body, response)
  }
}
