@preconcurrency import Foundation
import WrkstrmNetworking

public enum AlpacaAPIService: Sendable {
  case trading
  case marketData
}

public struct AlpacaCredentials: Sendable, Equatable {
  public let apiKeyID: String
  public let secretKey: String

  public init(apiKeyID: String, secretKey: String) {
    self.apiKeyID = apiKeyID
    self.secretKey = secretKey
  }

  public var hasCredentials: Bool {
    apiKeyID.isEmpty == false && secretKey.isEmpty == false
  }
}

public enum AlpacaEnvironment: Sendable, Equatable {
  case paper
  case live
  case custom(tradingBaseURL: URL, dataBaseURL: URL)

  public var tradingBaseURL: URL {
    switch self {
    case .paper:
      URL(string: "https://paper-api.alpaca.markets")!
    case .live:
      URL(string: "https://api.alpaca.markets")!
    case .custom(let tradingBaseURL, _):
      tradingBaseURL
    }
  }

  public var dataBaseURL: URL {
    switch self {
    case .paper, .live:
      URL(string: "https://data.alpaca.markets")!
    case .custom(_, let dataBaseURL):
      dataBaseURL
    }
  }
}

public enum AlpacaError: Error, Sendable, Equatable {
  case invalidURL(String)
  case httpStatus(Int, String)
  case unsupported(String)
}

public struct AlpacaEmptyResponse: Codable, Sendable, Equatable {
  public init() {}
}

public struct AlpacaHTTPEnvironment: HTTP.Environment {
  public let apiKey: String?
  public var scheme: HTTP.Scheme
  public var host: String
  public var apiVersion: String?
  public var clientVersion: String?
  private let secretKey: String

  public var headers: [String: String] {
    [
      "Accept": "application/json",
      "APCA-API-KEY-ID": apiKey ?? "",
      "APCA-API-SECRET-KEY": secretKey,
    ]
  }

  public init(
    credentials: AlpacaCredentials,
    baseURL: URL,
    apiVersion: String? = nil,
    clientVersion: String? = nil
  ) {
    apiKey = credentials.apiKeyID
    secretKey = credentials.secretKey
    scheme = baseURL.scheme == "http" ? .http : .https
    host = Self.hostPath(from: baseURL)
    self.apiVersion = apiVersion
    self.clientVersion = clientVersion
  }

  private static func hostPath(from url: URL) -> String {
    var authority = url.host ?? ""
    if let port = url.port {
      authority += ":\(port)"
    }
    let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    if path.isEmpty {
      return authority
    }
    return "\(authority)/\(path)"
  }
}
