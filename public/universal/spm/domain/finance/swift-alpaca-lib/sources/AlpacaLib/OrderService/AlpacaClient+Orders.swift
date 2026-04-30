import Foundation

extension AlpacaClient {
  public func placeOrder(_ order: AlpacaOrderRequest) async throws -> AlpacaOrder {
    try await send(AlpacaPlaceOrderURLRequest(order: order))
  }

  public func listOrders(
    status: String = "open",
    after: Date? = nil,
    until: Date? = nil,
    limit: Int? = nil
  ) async throws -> [AlpacaOrder] {
    try await send(
      AlpacaListOrdersURLRequest(status: status, after: after, until: until, limit: limit)
    )
  }

  public func order(id: String) async throws -> AlpacaOrder {
    try await send(try AlpacaOrderURLRequest(id: id))
  }

  public func replaceOrder(id: String, request: AlpacaReplaceOrderRequest) async throws -> AlpacaOrder {
    try await send(try AlpacaReplaceOrderURLRequest(id: id, request: request))
  }

  public func cancelOrder(id: String) async throws {
    let _: AlpacaEmptyResponse = try await send(try AlpacaCancelOrderURLRequest(id: id))
  }
}
