import Foundation
import Testing

@testable import OmniBrokerageLib

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import CommonBroker
import TradierBrokerageCommonAdapters

extension Bundle {
  func json(named name: String) throws -> Data {
    guard let url: URL = url(forResource: name, withExtension: "json") else {
      throw URLError(.fileDoesNotExist)
    }
    return try Data(contentsOf: url)
  }
}

@Test
func initDoesNotCrash() async throws {
  _ = OmniBroker()
  #expect(true)
}

@Test
func capabilityMatrix() async throws {
  let expected: [Broker: Set<BrokerageService>] = [
    .schwab: [.auth, .account, .quote, .watchlist],
    .tradier: [.auth, .account, .quote, .greeks, .watchlist, .positionStreaming],
    .public: [.auth, .account, .quote],
    .tastytrade: [.auth, .account],
  ]
  for (broker, services) in expected {
    let caps = BrokerRegistry.capabilities[broker]!
    for service in services {
      #expect(caps.supports(service))
    }
  }
}

@Test
func tradierAdapterAccounts() async throws {
  let configuration: URLSessionConfiguration = .ephemeral
  configuration.protocolClasses = [TradierURLProtocol.self]

  let json: Data = try Bundle.module.json(named: "tradier_user_profile")
  TradierURLProtocol.handler = { (_: URLRequest) in
    let url: URL =
      .init(string: "https://sandbox.tradier.com/v1/user/profile") ?? .init(fileURLWithPath: "/")
    let response: HTTPURLResponse =
      .init(
        url: url,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil,
      )!
    return (response, json)
  }

  let service = TradierAccountService(client: .init(configuration: configuration))
  let numbers = try await service.accountNumbers()
  #expect(numbers == ["VA000001", "VA000002"])

  let broker = OmniBroker(accountService: service)
  let brokerNumbers = try await broker.accountNumbers()
  #expect(brokerNumbers == numbers)
}

@Test
func authenticationStream() async throws {
  struct TestAuthService: AuthService {
    func authenticationStatus() -> AsyncStream<Bool> {
      AsyncStream { continuation in
        continuation.yield(true)
        continuation.finish()
      }
    }
  }
  let broker = OmniBroker(authService: TestAuthService())
  var iterator = await broker.authenticationStatus().makeAsyncIterator()
  let status = await iterator.next()
  #expect(status == true)
}

@Test
func serviceDelegatesToProvider() async throws {
  struct EchoProvider: ServiceProvider {
    func handle(_ requirement: String) async throws -> String { requirement }
  }
  let service: Service<String, String> = .init(EchoProvider())
  let result = try await service.request("ping")
  #expect(result == "ping")
}

final class TradierURLProtocol: URLProtocol {
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
