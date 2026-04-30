import Foundation

extension AlpacaClient {
  public func openPositions() async throws -> [AlpacaPosition] {
    try await send(AlpacaOpenPositionsURLRequest())
  }
}
