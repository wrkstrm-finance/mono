import AlpacaLib
import CommonBroker
import Foundation

public struct AlpacaWatchlistService: CommonWatchlistService, Sendable {
  public nonisolated let serviceName = "Alpaca"
  public nonisolated let serviceType: ServiceType
  private let client: AlpacaClient

  public init(client: AlpacaClient, serviceType: ServiceType = .sandbox) {
    self.client = client
    self.serviceType = serviceType
  }

  public func watchlists() async throws -> [CommonBrokerageWatchlistModel] {
    try await client.watchlists().map(commonWatchlist)
  }

  public func watchlist(id: String) async throws -> CommonBrokerageWatchlistModel {
    try await commonWatchlist(client.watchlist(id: id))
  }

  public func createWatchlist(name: String, symbols: [String]?) async throws -> CommonBrokerageWatchlistModel {
    try await commonWatchlist(client.createWatchlist(name: name, symbols: symbols))
  }

  public func add(symbols: [String], to watchlistId: String) async throws -> CommonBrokerageWatchlistModel {
    var result: AlpacaWatchlist?
    for symbol in symbols {
      result = try await client.addSymbol(symbol, toWatchlist: watchlistId)
    }
    if let result {
      return commonWatchlist(result)
    }
    return try await watchlist(id: watchlistId)
  }

  public func remove(symbol: String, from watchlistId: String) async throws -> CommonBrokerageWatchlistModel {
    try await commonWatchlist(client.removeSymbol(symbol, fromWatchlist: watchlistId))
  }

  public func deleteWatchlist(id: String) async throws {
    try await client.deleteWatchlist(id: id)
  }
}

func commonWatchlist(_ watchlist: AlpacaWatchlist) -> CommonBrokerageWatchlistModel {
  let assetItems = (watchlist.assets ?? []).map { asset in
    CommonBrokerageWatchlistItemModel(id: asset.id, symbol: asset.symbol)
  }
  let symbolItems = (watchlist.symbols ?? []).map { symbol in
    CommonBrokerageWatchlistItemModel(id: symbol, symbol: symbol)
  }
  return CommonBrokerageWatchlistModel(
    id: watchlist.id,
    name: watchlist.name,
    publicId: watchlist.accountId,
    items: assetItems.isEmpty ? symbolItems : assetItems
  )
}
