import WrkstrmNetworking

public struct AlpacaOptionContractsURLRequest: AlpacaURLRequest {
  public typealias ResponseType = AlpacaOptionContractsResponse

  public let service: AlpacaAPIService = .trading
  public var method: HTTP.Method { .get }
  public var path: String { "v2/options/contracts" }
  public let options: HTTP.Request.Options

  public init(
    underlyingSymbols: [String],
    expirationDate: String? = nil,
    expirationDateGte: String? = nil,
    expirationDateLte: String? = nil,
    type: String? = nil,
    limit: Int? = 10_000
  ) {
    options = .make { q in
      q.addJoined("underlying_symbols", values: underlyingSymbols)
      q.add("expiration_date", value: expirationDate)
      q.add("expiration_date_gte", value: expirationDateGte)
      q.add("expiration_date_lte", value: expirationDateLte)
      q.add("type", value: type)
      q.add("limit", value: limit)
    }
  }
}

public struct AlpacaOptionSnapshotsURLRequest: AlpacaURLRequest {
  public typealias ResponseType = AlpacaOptionSnapshotsResponse

  public let service: AlpacaAPIService = .marketData
  public var method: HTTP.Method { .get }
  public var path: String { "v1beta1/options/snapshots" }
  public let options: HTTP.Request.Options

  public init(symbols: [String], feed: String? = "indicative") {
    options = .make { q in
      q.addJoined("symbols", values: symbols)
      q.add("feed", value: feed)
    }
  }
}

public struct AlpacaOptionChainSnapshotsURLRequest: AlpacaURLRequest {
  public typealias ResponseType = AlpacaOptionSnapshotsResponse

  public let service: AlpacaAPIService = .marketData
  public var method: HTTP.Method { .get }
  public let path: String
  public let options: HTTP.Request.Options

  public init(
    underlyingSymbol: String,
    feed: String? = "indicative",
    expirationDate: String? = nil,
    type: String? = nil,
    limit: Int? = 1_000
  ) throws {
    path = "v1beta1/options/snapshots/\(try AlpacaClient.urlPathComponent(underlyingSymbol))"
    options = .make { q in
      q.add("feed", value: feed)
      q.add("expiration_date", value: expirationDate)
      q.add("type", value: type)
      q.add("limit", value: limit)
    }
  }
}
