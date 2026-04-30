import AlpacaLib
import CommonBroker
import Foundation

public struct AlpacaOrderService: CommonOrderService, CommonOrdersService, Sendable {
  public nonisolated let serviceName = "Alpaca"
  public nonisolated let serviceType: ServiceType
  private let client: AlpacaClient

  public init(client: AlpacaClient, serviceType: ServiceType = .sandbox) {
    self.client = client
    self.serviceType = serviceType
  }

  public func placeOrder(
    accountId _: String,
    symbol: String,
    side: CommonOrderSide,
    quantity: Int,
    type: CommonOrderType,
    duration: CommonOrderDuration,
    price: Double
  ) async throws -> CommonOrderResult {
    let order = try await client.placeOrder(
      AlpacaOrderRequest(
        symbol: symbol,
        qty: String(quantity),
        side: side.rawValue,
        type: type.rawValue,
        timeInForce: duration.rawValue,
        limitPrice: type == .limit ? decimalString(price) : nil
      )
    )
    return commonOrderResult(order)
  }

  public func previewOrder(
    accountId _: String,
    symbol _: String,
    side _: CommonOrderSide,
    quantity _: Int,
    type _: CommonOrderType,
    duration _: CommonOrderDuration,
    price _: Double
  ) async throws -> CommonOrderResult {
    throw AlpacaCommonAdapterError.unsupported("Alpaca does not expose an order preview endpoint.")
  }

  public func replaceOrder(
    accountId _: String,
    orderId: String,
    quantity: Int,
    price: Double,
    stop: Double?
  ) async throws -> CommonOrderResult {
    let order = try await client.replaceOrder(
      id: orderId,
      request: AlpacaReplaceOrderRequest(
        qty: String(quantity),
        limitPrice: decimalString(price),
        stopPrice: stop.map(decimalString)
      )
    )
    return commonOrderResult(order)
  }

  public func cancelOrder(accountId _: String, orderId: String) async throws -> CommonOrderResult {
    try await client.cancelOrder(id: orderId)
    return CommonOrderResult(
      id: commonIntegerID(orderId),
      status: "cancel_requested",
      partnerId: orderId
    )
  }

  public func orderStatus(accountId _: String, orderId: String) async throws -> CommonBrokerageOrderModel {
    try await commonOrderModel(client.order(id: orderId))
  }

  public func openOrders(
    for _: String,
    date _: Date?,
    start: Date?,
    end: Date?,
    page _: Int?,
    limit: Int?
  ) async throws -> [CommonBrokerageOrderModel] {
    try await client.listOrders(
      status: "open",
      after: start,
      until: end,
      limit: limit
    ).map(commonOrderModel)
  }
}

func commonOrderResult(_ order: AlpacaOrder) -> CommonOrderResult {
  CommonOrderResult(
    id: commonIntegerID(order.id),
    status: order.status,
    partnerId: order.id
  )
}

func commonOrderModel(_ order: AlpacaOrder) -> CommonBrokerageOrderModel {
  CommonBrokerageOrderModel(
    id: commonIntegerID(order.id),
    orderType: order.type,
    symbol: order.symbol,
    side: order.side,
    quantity: double(order.qty) ?? 0,
    status: order.status,
    duration: order.timeInForce,
    price: double(order.limitPrice ?? order.filledAvgPrice),
    createDate: order.createdAt,
    transactionDate: order.submittedAt ?? order.updatedAt
  )
}
