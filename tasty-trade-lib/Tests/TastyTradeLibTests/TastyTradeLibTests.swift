import Foundation
import Testing

@testable import TastyTradeLib

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension Bundle {
  func json(named name: String) throws -> Data {
    guard let url: URL = url(forResource: name, withExtension: "json") else {
      throw URLError(.fileDoesNotExist)
    }
    return try Data(contentsOf: url)
  }
}

@Suite
struct TastyTradeClientTests {
  @Test
  func fetchAccountsParsesAccountNumbers() async throws {
    let configuration: URLSessionConfiguration = .ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]

    let json: Data = try Bundle.module.json(named: "accounts")

    MockURLProtocol.handler = { (_: URLRequest) in
      let url: URL =
        .init(string: "https://api.tastytrade.com/accounts") ?? .init(fileURLWithPath: "/")
      let response: HTTPURLResponse =
        .init(
          url: url,
          statusCode: 200,
          httpVersion: nil,
          headerFields: nil,
        )!
      return (response, json)
    }

    let client: TastyTradeClient = .init(configuration: configuration)
    let accounts: [String] = try await client.fetchAccounts()
    #expect(accounts == ["123", "456"])
  }
}

final class MockURLProtocol: URLProtocol {
  nonisolated(unsafe) static var handler: (@Sendable (URLRequest) -> (HTTPURLResponse, Data))?
  override class func canInit(with _: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    guard let handler = Self.handler else {
      client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
      return
    }
    let (response, data) = handler(request)
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: data)
    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}
}
