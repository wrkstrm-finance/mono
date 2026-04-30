import AlpacaLib
import CommonBroker
import Foundation

public struct AlpacaAuthService: AuthService, Sendable {
  private let credentials: AlpacaCredentials

  public init(credentials: AlpacaCredentials) {
    self.credentials = credentials
  }

  public func authenticationStatus() -> AsyncStream<Bool> {
    AsyncStream { continuation in
      continuation.yield(credentials.hasCredentials)
      continuation.finish()
    }
  }
}

public struct AlpacaAccountService: AccountService, Sendable {
  private let client: AlpacaClient

  public init(client: AlpacaClient) {
    self.client = client
  }

  public func accountNumbers() async throws -> [String] {
    let account = try await client.account()
    return [account.accountNumber ?? account.id]
  }
}

public struct AlpacaProfileService: CommonProfileService, Sendable {
  public nonisolated let serviceName = "Alpaca"
  public nonisolated let serviceType: ServiceType
  private let client: AlpacaClient

  public init(client: AlpacaClient, serviceType: ServiceType = .sandbox) {
    self.client = client
    self.serviceType = serviceType
  }

  public func userProfile() async throws -> CommonBrokerageUserProfileModel {
    let account = try await client.account()
    return CommonBrokerageUserProfileModel(
      id: account.id,
      name: account.accountNumber,
      email: nil
    )
  }

  public func accountProfile(for accountId: String) async throws -> CommonBrokerageAccountProfileModel {
    let account = try await client.account()
    return CommonBrokerageAccountProfileModel(
      accountId: accountId.isEmpty ? account.id : accountId,
      status: account.status,
      classification: account.cryptoStatus,
      displayName: account.accountNumber,
      accountType: nil,
      optionLevel: nil,
      dayTrader: account.patternDayTrader,
      lastUpdated: account.createdAt,
      email: nil,
      phone: nil,
      address: nil
    )
  }

  public func accountBalances(for _: String) async throws -> CommonBrokerageAccountBalanceModel {
    let account = try await client.account()
    return CommonBrokerageAccountBalanceModel(
      accountNumber: account.accountNumber ?? account.id,
      accountType: nil,
      totalCash: double(account.cash),
      totalEquity: double(account.equity ?? account.portfolioValue),
      longMarketValue: double(account.longMarketValue),
      shortMarketValue: double(account.shortMarketValue),
      closedProfitLoss: nil,
      openProfitLoss: nil,
      pendingOrdersCount: nil,
      federalFundsCall: nil,
      maintenanceRequirement: double(account.maintenanceMargin),
      stockBuyingPower: double(account.buyingPower),
      optionBuyingPower: nil,
      cashAvailable: double(account.cash),
      unsettledFunds: nil,
      sweep: nil
    )
  }
}
