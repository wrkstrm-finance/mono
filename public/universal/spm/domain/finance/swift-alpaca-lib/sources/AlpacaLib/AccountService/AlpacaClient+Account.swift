import Foundation

extension AlpacaClient {
  public func account() async throws -> AlpacaAccount {
    try await send(AlpacaAccountURLRequest())
  }
}
