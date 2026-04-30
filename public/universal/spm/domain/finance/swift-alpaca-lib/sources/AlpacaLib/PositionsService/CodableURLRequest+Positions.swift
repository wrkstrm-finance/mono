import WrkstrmNetworking

public struct AlpacaOpenPositionsURLRequest: AlpacaURLRequest {
  public typealias ResponseType = [AlpacaPosition]

  public let service: AlpacaAPIService = .trading
  public var method: HTTP.Method { .get }
  public var path: String { "v2/positions" }

  public init() {}
}
