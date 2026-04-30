import AlpacaLib
import CommonBroker
import Foundation

public struct AlpacaPositionsService: CommonPositionsService, Sendable {
  public nonisolated let serviceName = "Alpaca"
  public nonisolated let serviceType: ServiceType
  private let client: AlpacaClient

  public init(client: AlpacaClient, serviceType: ServiceType = .sandbox) {
    self.client = client
    self.serviceType = serviceType
  }

  public func positions(for accountId: String) async throws -> [CommonBrokeragePositionModel] {
    try await client.openPositions().map { position in
      CommonBrokeragePositionModel(
        symbol: position.symbol,
        quantity: double(position.qty) ?? 0,
        costBasis: double(position.costBasis),
        marketValue: double(position.marketValue),
        side: position.side,
        id: position.assetId.map(commonIntegerID),
        account: nil,
        accountId: accountId.isEmpty ? nil : accountId,
        dateAcquired: nil,
        pricePaid: double(position.avgEntryPrice),
        expirationDate: nil,
        strikePrice: nil,
        optionKind: nil,
        underlying: nil
      )
    }
  }

  public func livePositions(for accountId: String) async throws -> [CommonBrokeragePositionModel] {
    try await positions(for: accountId)
  }
}
