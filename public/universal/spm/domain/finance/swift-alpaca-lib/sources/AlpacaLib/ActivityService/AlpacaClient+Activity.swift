import Foundation

extension AlpacaClient {
  public func accountActivities(
    activityType: String? = nil,
    after: Date? = nil,
    until: Date? = nil,
    pageSize: Int? = nil
  ) async throws -> [AlpacaActivity] {
    let request = try AlpacaAccountActivitiesURLRequest(
      activityType: activityType,
      after: after,
      until: until,
      pageSize: pageSize
    )
    return try await send(request)
  }
}
