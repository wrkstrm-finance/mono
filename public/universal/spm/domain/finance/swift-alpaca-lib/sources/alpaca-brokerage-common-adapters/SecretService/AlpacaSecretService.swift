import CommonBroker
import Foundation

private actor AlpacaSecretStore {
  private var secrets: [Broker: Data] = [:]

  func storeSecret(_ secret: Data, for broker: Broker) {
    secrets[broker] = secret
  }

  func secret(for broker: Broker) -> Data? {
    secrets[broker]
  }
}

public struct AlpacaSecretService: SecretService, Sendable {
  private let store: AlpacaSecretStore

  public init() {
    store = AlpacaSecretStore()
  }

  public func storeSecret(_ secret: Data, for broker: Broker) async throws {
    await store.storeSecret(secret, for: broker)
  }

  public func secret(for broker: Broker) async throws -> Data? {
    await store.secret(for: broker)
  }
}
