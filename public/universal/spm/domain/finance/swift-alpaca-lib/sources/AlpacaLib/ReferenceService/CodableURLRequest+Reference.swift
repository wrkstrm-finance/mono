import WrkstrmNetworking

public struct AlpacaAssetsURLRequest: AlpacaURLRequest {
  public typealias ResponseType = [AlpacaAsset]

  public let service: AlpacaAPIService = .trading
  public var method: HTTP.Method { .get }
  public var path: String { "v2/assets" }
  public let options: HTTP.Request.Options

  public init(status: String? = "active", assetClass: String? = "us_equity") {
    options = .make { q in
      q.add("status", value: status)
      q.add("asset_class", value: assetClass)
    }
  }
}
