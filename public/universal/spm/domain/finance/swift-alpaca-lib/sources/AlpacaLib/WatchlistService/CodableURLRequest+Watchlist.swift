import WrkstrmNetworking

public struct AlpacaWatchlistsURLRequest: AlpacaURLRequest {
  public typealias ResponseType = [AlpacaWatchlist]

  public let service: AlpacaAPIService = .trading
  public var method: HTTP.Method { .get }
  public var path: String { "v2/watchlists" }

  public init() {}
}

public struct AlpacaWatchlistURLRequest: AlpacaURLRequest {
  public typealias ResponseType = AlpacaWatchlist

  public let service: AlpacaAPIService = .trading
  public var method: HTTP.Method { .get }
  public let path: String

  public init(id: String) throws {
    path = "v2/watchlists/\(try AlpacaClient.urlPathComponent(id))"
  }
}

public struct AlpacaCreateWatchlistURLRequest: AlpacaURLRequest {
  public typealias ResponseType = AlpacaWatchlist
  public typealias RequestBody = AlpacaWatchlistRequest

  public let service: AlpacaAPIService = .trading
  public var method: HTTP.Method { .post }
  public var path: String { "v2/watchlists" }
  public let body: AlpacaWatchlistRequest?
  public let options: HTTP.Request.Options

  public init(name: String, symbols: [String]?) {
    body = AlpacaWatchlistRequest(name: name, symbols: symbols)
    options = .init(headers: ["Content-Type": "application/json"])
  }
}

public struct AlpacaUpdateWatchlistURLRequest: AlpacaURLRequest {
  public typealias ResponseType = AlpacaWatchlist
  public typealias RequestBody = AlpacaWatchlistRequest

  public let service: AlpacaAPIService = .trading
  public var method: HTTP.Method { .put }
  public let path: String
  public let body: AlpacaWatchlistRequest?
  public let options: HTTP.Request.Options

  public init(id: String, name: String, symbols: [String]?) throws {
    path = "v2/watchlists/\(try AlpacaClient.urlPathComponent(id))"
    body = AlpacaWatchlistRequest(name: name, symbols: symbols)
    options = .init(headers: ["Content-Type": "application/json"])
  }
}

public struct AlpacaAddWatchlistSymbolURLRequest: AlpacaURLRequest {
  public typealias ResponseType = AlpacaWatchlist
  public typealias RequestBody = AlpacaWatchlistSymbolRequest

  public let service: AlpacaAPIService = .trading
  public var method: HTTP.Method { .post }
  public let path: String
  public let body: AlpacaWatchlistSymbolRequest?
  public let options: HTTP.Request.Options

  public init(symbol: String, watchlistID: String) throws {
    path = "v2/watchlists/\(try AlpacaClient.urlPathComponent(watchlistID))"
    body = AlpacaWatchlistSymbolRequest(symbol: symbol)
    options = .init(headers: ["Content-Type": "application/json"])
  }
}

public struct AlpacaRemoveWatchlistSymbolURLRequest: AlpacaURLRequest {
  public typealias ResponseType = AlpacaWatchlist

  public let service: AlpacaAPIService = .trading
  public var method: HTTP.Method { .delete }
  public let path: String

  public init(symbol: String, watchlistID: String) throws {
    path = "v2/watchlists/\(try AlpacaClient.urlPathComponent(watchlistID))/\(try AlpacaClient.urlPathComponent(symbol))"
  }
}

public struct AlpacaDeleteWatchlistURLRequest: AlpacaURLRequest {
  public typealias ResponseType = AlpacaEmptyResponse

  public let service: AlpacaAPIService = .trading
  public var method: HTTP.Method { .delete }
  public let path: String

  public init(id: String) throws {
    path = "v2/watchlists/\(try AlpacaClient.urlPathComponent(id))"
  }
}
