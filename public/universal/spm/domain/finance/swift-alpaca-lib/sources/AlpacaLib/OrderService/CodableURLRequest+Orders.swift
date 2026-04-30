import Foundation
import WrkstrmNetworking

public struct AlpacaPlaceOrderURLRequest: AlpacaURLRequest {
  public typealias ResponseType = AlpacaOrder
  public typealias RequestBody = AlpacaOrderRequest

  public let service: AlpacaAPIService = .trading
  public var method: HTTP.Method { .post }
  public var path: String { "v2/orders" }
  public let body: AlpacaOrderRequest?
  public let options: HTTP.Request.Options

  public init(order: AlpacaOrderRequest) {
    body = order
    options = .init(headers: ["Content-Type": "application/json"])
  }
}

public struct AlpacaListOrdersURLRequest: AlpacaURLRequest {
  public typealias ResponseType = [AlpacaOrder]

  public let service: AlpacaAPIService = .trading
  public var method: HTTP.Method { .get }
  public var path: String { "v2/orders" }
  public let options: HTTP.Request.Options

  public init(status: String = "open", after: Date? = nil, until: Date? = nil, limit: Int? = nil) {
    options = .make { q in
      q.add("status", value: status)
      q.add("after", value: after.map(AlpacaClient.formatDate))
      q.add("until", value: until.map(AlpacaClient.formatDate))
      q.add("limit", value: limit)
    }
  }
}

public struct AlpacaOrderURLRequest: AlpacaURLRequest {
  public typealias ResponseType = AlpacaOrder

  public let service: AlpacaAPIService = .trading
  public var method: HTTP.Method { .get }
  public let path: String

  public init(id: String) throws {
    path = "v2/orders/\(try AlpacaClient.urlPathComponent(id))"
  }
}

public struct AlpacaReplaceOrderURLRequest: AlpacaURLRequest {
  public typealias ResponseType = AlpacaOrder
  public typealias RequestBody = AlpacaReplaceOrderRequest

  public let service: AlpacaAPIService = .trading
  public var method: HTTP.Method { .patch }
  public let path: String
  public let body: AlpacaReplaceOrderRequest?
  public let options: HTTP.Request.Options

  public init(id: String, request: AlpacaReplaceOrderRequest) throws {
    path = "v2/orders/\(try AlpacaClient.urlPathComponent(id))"
    body = request
    options = .init(headers: ["Content-Type": "application/json"])
  }
}

public struct AlpacaCancelOrderURLRequest: AlpacaURLRequest {
  public typealias ResponseType = AlpacaEmptyResponse

  public let service: AlpacaAPIService = .trading
  public var method: HTTP.Method { .delete }
  public let path: String

  public init(id: String) throws {
    path = "v2/orders/\(try AlpacaClient.urlPathComponent(id))"
  }
}
