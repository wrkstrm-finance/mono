import CommonBroker
import PublicBrokerageCommonAdapters
import PublicBrokerageLib
import TradierBrokerageCommonAdapters

public enum OmniBrokerError: Error, Sendable {
  case missingPublicQuoteService
  case unsupportedBroker(Broker)
}

public actor OmniBroker {
  private let defaultBroker: Broker
  private let tradierQuoteService: any CommonQuoteVariantService
  private let publicQuoteService: (any CommonQuoteVariantService)?
  private let accountService: any AccountService
  private let authService: any AuthService

  public init(
    defaultBroker: Broker = .tradier,
    tradierQuoteService: any CommonQuoteVariantService = TradierSandboxQuoteService(),
    publicQuoteService: (any CommonQuoteVariantService)? = nil,
    accountService: any AccountService = TradierAccountService(),
    authService: any AuthService = StaticAuthService(),
  ) {
    self.defaultBroker = defaultBroker
    self.tradierQuoteService = tradierQuoteService
    self.publicQuoteService = publicQuoteService
    self.accountService = accountService
    self.authService = authService
  }

  public init(
    publicClient: PublicClient,
    publicServiceType: ServiceType = .production,
    defaultBroker: Broker = .tradier,
    tradierQuoteService: any CommonQuoteVariantService = TradierSandboxQuoteService(),
    accountService: any AccountService = TradierAccountService(),
    authService: any AuthService = StaticAuthService(),
  ) {
    self.init(
      defaultBroker: defaultBroker,
      tradierQuoteService: tradierQuoteService,
      publicQuoteService: PublicQuoteCommonService(
        client: publicClient,
        serviceType: publicServiceType
      ),
      accountService: accountService,
      authService: authService
    )
  }

  public func quote(for symbol: String, accountId: String) async throws -> CommonQuoteVariant {
    try await quote(for: symbol, accountId: accountId, broker: defaultBroker)
  }

  public func quote(
    for symbol: String,
    accountId: String,
    broker: Broker,
  ) async throws -> CommonQuoteVariant {
    let service: any CommonQuoteVariantService = try quoteService(for: broker)
    return try await service.quoteVariant(for: symbol, accountId: accountId, detail: .full)
  }

  public func quoteVariant(
    for symbol: String,
    accountId: String,
    broker: Broker,
    detail: QuoteDetail,
  ) async throws -> CommonQuoteVariant {
    let service: any CommonQuoteVariantService = try quoteService(for: broker)
    return try await service.quoteVariant(for: symbol, accountId: accountId, detail: detail)
  }

  public func accountNumbers() async throws -> [String] {
    try await accountService.accountNumbers()
  }

  public func authenticationStatus() -> AsyncStream<Bool> {
    authService.authenticationStatus()
  }

  private func quoteService(for broker: Broker) throws -> any CommonQuoteVariantService {
    switch broker {
    case .tradier:
      return tradierQuoteService
    case .public:
      guard let publicQuoteService else { throw OmniBrokerError.missingPublicQuoteService }
      return publicQuoteService
    default:
      throw OmniBrokerError.unsupportedBroker(broker)
    }
  }
}
