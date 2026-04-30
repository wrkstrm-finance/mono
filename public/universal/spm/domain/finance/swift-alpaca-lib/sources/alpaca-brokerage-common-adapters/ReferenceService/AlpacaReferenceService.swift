import AlpacaLib
import CommonBroker
import Foundation

public struct AlpacaReferenceService: CommonReferenceService, Sendable {
  public nonisolated let serviceName = "Alpaca"
  public nonisolated let serviceType: ServiceType
  private let client: AlpacaClient
  private let assetClass: String?

  public init(client: AlpacaClient, assetClass: String? = "us_equity", serviceType: ServiceType = .sandbox) {
    self.client = client
    self.assetClass = assetClass
    self.serviceType = serviceType
  }

  public func searchSymbols(_ query: String) async throws -> [CommonBrokerageSymbolModel] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    let assets = try await client.assets(status: "active", assetClass: assetClass)
    let filtered: [AlpacaAsset]
    if trimmed.isEmpty {
      filtered = assets
    } else {
      let needle = trimmed.lowercased()
      filtered = assets.filter { asset in
        asset.symbol.lowercased().contains(needle)
          || (asset.name?.lowercased().contains(needle) ?? false)
      }
    }
    return filtered.map { asset in
      CommonBrokerageSymbolModel(
        symbol: asset.symbol,
        name: asset.name ?? asset.symbol,
        exchange: asset.exchange,
        type: asset.class
      )
    }
  }
}
