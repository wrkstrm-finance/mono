@preconcurrency import Foundation
import AlpacaSchemas_v000_001_000
import WrkstrmNetworking

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct AlpacaClient: Sendable {
  public let credentials: AlpacaCredentials
  public let environment: AlpacaEnvironment
  private let httpClient: AlpacaNetworkingClient

  public init(
    credentials: AlpacaCredentials,
    environment: AlpacaEnvironment = .paper,
    transport: any HTTP.Transport = HTTP.URLSessionTransport()
  ) {
    self.credentials = credentials
    self.environment = environment
    httpClient = AlpacaNetworkingClient(
      credentials: credentials,
      environment: environment,
      transport: transport
    )
  }

  func send<Request: AlpacaURLRequest>(_ request: Request) async throws -> Request.ResponseType {
    try await httpClient.send(request)
  }

  static func urlPathComponent(_ value: String) throws -> String {
    guard let encoded = value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
      throw AlpacaError.invalidURL(value)
    }
    return encoded
  }

  static func makeJSONDecoder() -> JSONDecoder {
    AlpacaSchemas_v000_001_000.Alpaca.decoder
  }

  static func makeJSONEncoder() -> JSONEncoder {
    AlpacaSchemas_v000_001_000.Alpaca.encoder
  }

  static func formatDate(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
  }
}
