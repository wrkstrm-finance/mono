@preconcurrency import Foundation
import Testing
import WrkstrmNetworking

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@testable import AlpacaLib

@Test
func latestQuoteUsesMarketDataEndpointAndAuthHeaders() async throws {
  let http = StubHTTPClient(
    statusCode: 200,
    body: try fixture(named: "latest_stock_quote")
  )
  let client = AlpacaClient(
    credentials: .init(apiKeyID: "key-id", secretKey: "secret"),
    environment: .custom(
      tradingBaseURL: URL(string: "https://paper.example.test")!,
      dataBaseURL: URL(string: "https://data.example.test")!
    ),
    transport: http
  )

  let quote = try await client.latestStockQuote(symbol: "GOOG")
  let request = try #require(await http.recordedRequests().first)

  #expect(quote.bidPrice == 342.31)
  #expect(quote.askPrice == 342.35)
  #expect(request.method == "GET")
  #expect(request.host == "data.example.test")
  #expect(request.path == "/v2/stocks/GOOG/quotes/latest")
  #expect(request.query["feed"] == "iex")
  #expect(request.headers["APCA-API-KEY-ID"] == "key-id")
  #expect(request.headers["APCA-API-SECRET-KEY"] == "secret")
}

@Test
func placeOrderEncodesSnakeCasePayload() async throws {
  let http = StubHTTPClient(
    statusCode: 200,
    body: try fixture(named: "place_order_response")
  )
  let client = AlpacaClient(
    credentials: .init(apiKeyID: "key-id", secretKey: "secret"),
    environment: .custom(
      tradingBaseURL: URL(string: "https://paper.example.test")!,
      dataBaseURL: URL(string: "https://data.example.test")!
    ),
    transport: http
  )

  let order = try await client.placeOrder(
    AlpacaOrderRequest(
      symbol: "GOOG",
      qty: "1",
      side: "buy",
      type: "limit",
      timeInForce: "day",
      limitPrice: "342.32"
    )
  )
  let request = try #require(await http.recordedRequests().first)

  #expect(order.id == "order-1")
  #expect(request.method == "POST")
  #expect(request.path == "/v2/orders")
  #expect(request.body?.contains("\"time_in_force\":\"day\"") == true)
  #expect(request.body?.contains("\"limit_price\":\"342.32\"") == true)
}

@Test
func marketClockUsesTradingEndpoint() async throws {
  let http = StubHTTPClient(
    statusCode: 200,
    body: try fixture(named: "market_clock")
  )
  let client = AlpacaClient(
    credentials: .init(apiKeyID: "key-id", secretKey: "secret"),
    environment: .custom(
      tradingBaseURL: URL(string: "https://paper.example.test")!,
      dataBaseURL: URL(string: "https://data.example.test")!
    ),
    transport: http
  )

  let clock = try await client.marketClock()
  let request = try #require(await http.recordedRequests().first)

  #expect(clock.isOpen == true)
  #expect(request.method == "GET")
  #expect(request.host == "paper.example.test")
  #expect(request.path == "/v2/clock")
}

@Test
func optionContractsUseTradingEndpointAndQueryItems() async throws {
  let http = StubHTTPClient(
    statusCode: 200,
    body: try fixture(named: "option_contracts_single")
  )
  let client = AlpacaClient(
    credentials: .init(apiKeyID: "key-id", secretKey: "secret"),
    environment: .custom(
      tradingBaseURL: URL(string: "https://paper.example.test")!,
      dataBaseURL: URL(string: "https://data.example.test")!
    ),
    transport: http
  )

  let response = try await client.optionContracts(
    underlyingSymbols: ["AAPL"],
    expirationDate: "2026-01-16",
    type: "call"
  )
  let request = try #require(await http.recordedRequests().first)

  #expect(response.optionContracts.first?.symbol == "AAPL260116C00195000")
  #expect(request.host == "paper.example.test")
  #expect(request.path == "/v2/options/contracts")
  #expect(request.query["underlying_symbols"] == "AAPL")
  #expect(request.query["expiration_date"] == "2026-01-16")
  #expect(request.query["type"] == "call")
}

@Test
func addWatchlistSymbolEncodesPayload() async throws {
  let http = StubHTTPClient(
    statusCode: 200,
    body: try fixture(named: "watchlist_with_asset")
  )
  let client = AlpacaClient(
    credentials: .init(apiKeyID: "key-id", secretKey: "secret"),
    environment: .custom(
      tradingBaseURL: URL(string: "https://paper.example.test")!,
      dataBaseURL: URL(string: "https://data.example.test")!
    ),
    transport: http
  )

  let watchlist = try await client.addSymbol("GOOG", toWatchlist: "watchlist-1")
  let request = try #require(await http.recordedRequests().first)

  #expect(watchlist.assets?.first?.symbol == "GOOG")
  #expect(request.method == "POST")
  #expect(request.path == "/v2/watchlists/watchlist-1")
  #expect(request.body?.contains("\"symbol\":\"GOOG\"") == true)
}

private func fixture(named name: String) throws -> String {
  guard let url = Bundle.module.url(forResource: name, withExtension: "json") else {
    throw URLError(.fileDoesNotExist)
  }
  return try String(contentsOf: url, encoding: .utf8)
}

private actor StubHTTPClient: HTTP.Transport {
  private let statusCode: Int
  private let body: Data
  private var requests: [RecordedRequest] = []

  init(statusCode: Int, body: String) {
    self.statusCode = statusCode
    self.body = Data(body.utf8)
  }

  func execute(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
    requests.append(RecordedRequest(request: request))
    let response = HTTPURLResponse(
      url: request.url ?? URL(string: "https://example.test")!,
      statusCode: statusCode,
      httpVersion: nil,
      headerFields: nil
    )!
    return (body, response)
  }

  func recordedRequests() -> [RecordedRequest] {
    requests
  }
}

private struct RecordedRequest: Sendable {
  let method: String?
  let host: String?
  let path: String
  let query: [String: String]
  let headers: [String: String]
  let body: String?

  init(request: URLRequest) {
    method = request.httpMethod
    host = request.url?.host
    path = request.url?.path ?? ""
    query = Dictionary(
      uniqueKeysWithValues: URLComponents(
        url: request.url ?? URL(string: "https://example.test")!,
        resolvingAgainstBaseURL: false
      )?.queryItems?.compactMap { item in
        item.value.map { (item.name, $0) }
      } ?? []
    )
    headers = request.allHTTPHeaderFields ?? [:]
    body = request.httpBody.map { String(decoding: $0, as: UTF8.self) }
  }
}
