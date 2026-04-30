import Foundation

extension AlpacaClient {
  public func assets(
    status: String? = "active",
    assetClass: String? = "us_equity"
  ) async throws -> [AlpacaAsset] {
    try await send(AlpacaAssetsURLRequest(status: status, assetClass: assetClass))
  }
}
