import WrkstrmNetworking

public struct AlpacaAccountURLRequest: AlpacaURLRequest {
  public typealias ResponseType = AlpacaAccount

  public let service: AlpacaAPIService = .trading
  public var method: HTTP.Method { .get }
  public var path: String { "v2/account" }

  public init() {}
}
