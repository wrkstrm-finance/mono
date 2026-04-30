@preconcurrency import Foundation
import CommonLog
import WrkstrmNetworking

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol AlpacaURLRequest: HTTP.Request.Encodable, URLRequestConvertible {
  var service: AlpacaAPIService { get }
}

extension AlpacaURLRequest where RequestBody == Never {
  public var options: HTTP.Request.Options { .init() }
}

struct AlpacaNetworkingClient: @unchecked Sendable {
  private let tradingEnvironment: AlpacaHTTPEnvironment
  private let marketDataEnvironment: AlpacaHTTPEnvironment
  private let tradingExecutor: HTTP.RequestExecutor
  private let marketDataExecutor: HTTP.RequestExecutor
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  init(
    credentials: AlpacaCredentials,
    environment: AlpacaEnvironment,
    transport: any HTTP.Transport
  ) {
    let tradingEnvironment = AlpacaHTTPEnvironment(
      credentials: credentials,
      baseURL: environment.tradingBaseURL
    )
    let marketDataEnvironment = AlpacaHTTPEnvironment(
      credentials: credentials,
      baseURL: environment.dataBaseURL
    )
    self.tradingEnvironment = tradingEnvironment
    self.marketDataEnvironment = marketDataEnvironment
    tradingExecutor = HTTP.RequestExecutor(environment: tradingEnvironment, transport: transport)
    marketDataExecutor = HTTP.RequestExecutor(environment: marketDataEnvironment, transport: transport)
    encoder = AlpacaClient.makeJSONEncoder()
    decoder = AlpacaClient.makeJSONDecoder()
  }

  func send<Request: AlpacaURLRequest>(_ request: Request) async throws -> Request.ResponseType {
    let environment = request.service == .trading ? tradingEnvironment : marketDataEnvironment
    let executor = request.service == .trading ? tradingExecutor : marketDataExecutor
    let requestDescription = "\(request.method.rawValue) \(request.path)"

    let urlRequest = try request.asURLRequest(with: environment, encoder: encoder)
    let raw: HTTP.Response<Data>
    do {
      raw = try await executor.send(urlRequest)
    } catch {
      Log.error("Alpaca \(requestDescription) failed: \(error.localizedDescription)")
      throw error
    }

    if raw.value.isEmpty, let empty = AlpacaEmptyResponse() as? Request.ResponseType {
      return empty
    }

    do {
      return try decoder.decode(Request.ResponseType.self, from: raw.value)
    } catch {
      Log.error("Alpaca \(requestDescription) decode failed: \(error.localizedDescription)")
      throw error
    }
  }
}
