import Foundation
import WrkstrmFoundation
import CommonLog
import WrkstrmMain
import WrkstrmNetworking

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct TastyTradeClient: Sendable {
  private let http: HTTP.JSONClient

  public init(
    environment: any HTTP.Environment = TastytradeEnvironment(),
    configuration: URLSessionConfiguration = .default,
  ) {
    http = HTTP.JSONClient(
      environment: environment,
      json: (.commonDateFormatting, .commonDateParsing),
      configuration: configuration,
    )
  }

  public func fetchAccounts() async throws -> [String] {
    let json: JSON.AnyDictionary = try await http.send(AccountsRequest())
    let data: Data = try JSONSerialization.data(withJSONObject: json)
    let response: AccountsResponse = try JSONDecoder.commonDateParsing.decode(
      AccountsResponse.self,
      from: data,
    )
    return response.data.map(\.accountNumber)
  }
}

extension TastyTradeClient {
  struct AccountsRequest: HTTP.CodableURLRequest {
    typealias ResponseType = AccountsResponse
    var method: HTTP.Method { .get }
    var path: String { "accounts" }
    var options: HTTP.Request.Options = .init()
  }

  struct AccountsResponse: Codable, Equatable, Sendable {
    let data: [Account]
  }

  struct Account: Codable, Equatable, Sendable {
    let accountNumber: String

    enum CodingKeys: String, CodingKey {
      case accountNumber = "account_number"
    }
  }
}

public struct TastytradeEnvironment: HTTP.Environment {
  public var apiKey: String?
  public var headers: HTTP.Client.Headers = [:]
  public var scheme: HTTP.Scheme = .https
  public var host: String = "api.tastytrade.com"
  public var apiVersion: String?
  public var clientVersion: String?
  public init() {}
}
