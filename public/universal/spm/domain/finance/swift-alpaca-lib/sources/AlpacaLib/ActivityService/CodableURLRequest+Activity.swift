import Foundation
import WrkstrmNetworking

public struct AlpacaAccountActivitiesURLRequest: AlpacaURLRequest {
  public typealias ResponseType = [AlpacaActivity]

  public let service: AlpacaAPIService = .trading
  public var method: HTTP.Method { .get }
  public let path: String
  public let options: HTTP.Request.Options

  public init(
    activityType: String? = nil,
    after: Date? = nil,
    until: Date? = nil,
    pageSize: Int? = nil
  ) throws {
    if let activityType {
      path = "v2/account/activities/\(try AlpacaClient.urlPathComponent(activityType))"
    } else {
      path = "v2/account/activities"
    }
    options = .make { q in
      q.add("after", value: after.map(AlpacaClient.formatDate))
      q.add("until", value: until.map(AlpacaClient.formatDate))
      q.add("page_size", value: pageSize)
    }
  }
}
