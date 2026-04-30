import Foundation

extension AlpacaClient {
  public func optionContracts(
    underlyingSymbols: [String],
    expirationDate: String? = nil,
    expirationDateGte: String? = nil,
    expirationDateLte: String? = nil,
    type: String? = nil,
    limit: Int? = 10_000
  ) async throws -> AlpacaOptionContractsResponse {
    try await send(
      AlpacaOptionContractsURLRequest(
        underlyingSymbols: underlyingSymbols,
        expirationDate: expirationDate,
        expirationDateGte: expirationDateGte,
        expirationDateLte: expirationDateLte,
        type: type,
        limit: limit
      )
    )
  }

  public func optionSnapshots(
    symbols: [String],
    feed: String? = "indicative"
  ) async throws -> AlpacaOptionSnapshotsResponse {
    try await send(AlpacaOptionSnapshotsURLRequest(symbols: symbols, feed: feed))
  }

  public func optionChainSnapshots(
    underlyingSymbol: String,
    feed: String? = "indicative",
    expirationDate: String? = nil,
    type: String? = nil,
    limit: Int? = 1_000
  ) async throws -> AlpacaOptionSnapshotsResponse {
    let request = try AlpacaOptionChainSnapshotsURLRequest(
      underlyingSymbol: underlyingSymbol,
      feed: feed,
      expirationDate: expirationDate,
      type: type,
      limit: limit
    )
    return try await send(request)
  }
}
