import Foundation

extension AlpacaClient {
  public func watchlists() async throws -> [AlpacaWatchlist] {
    try await send(AlpacaWatchlistsURLRequest())
  }

  public func watchlist(id: String) async throws -> AlpacaWatchlist {
    try await send(try AlpacaWatchlistURLRequest(id: id))
  }

  public func createWatchlist(name: String, symbols: [String]?) async throws -> AlpacaWatchlist {
    try await send(AlpacaCreateWatchlistURLRequest(name: name, symbols: symbols))
  }

  public func updateWatchlist(id: String, name: String, symbols: [String]?) async throws -> AlpacaWatchlist {
    try await send(try AlpacaUpdateWatchlistURLRequest(id: id, name: name, symbols: symbols))
  }

  public func addSymbol(_ symbol: String, toWatchlist id: String) async throws -> AlpacaWatchlist {
    try await send(try AlpacaAddWatchlistSymbolURLRequest(symbol: symbol, watchlistID: id))
  }

  public func removeSymbol(_ symbol: String, fromWatchlist id: String) async throws -> AlpacaWatchlist {
    try await send(try AlpacaRemoveWatchlistSymbolURLRequest(symbol: symbol, watchlistID: id))
  }

  public func deleteWatchlist(id: String) async throws {
    let _: AlpacaEmptyResponse = try await send(try AlpacaDeleteWatchlistURLRequest(id: id))
  }
}
