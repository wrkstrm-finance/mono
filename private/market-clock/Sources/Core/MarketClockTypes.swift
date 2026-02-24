import Foundation

public enum MarketClockKind: String, Sendable, Codable {
  case regular
  case premarket
  case afterHours
  case futures
}

public struct MarketSession: Sendable, Equatable, Codable {
  public let start: Date
  public let end: Date
  public let kind: MarketClockKind
  public let timeZone: TimeZone

  public init(start: Date, end: Date, kind: MarketClockKind, timeZone: TimeZone) {
    self.start = start
    self.end = end
    self.kind = kind
    self.timeZone = timeZone
  }
}

public enum MarketClockEvent: Sendable, Equatable {
  case opensIn(minutes: Int)
  case closesIn(minutes: Int)
  case opened
  case closed
}

public enum BrokerAuthState: Sendable, Equatable {
  case authorized
  case unauthorized
  case refreshing
  case throttled
}

public enum ConnectivityState: Sendable, Equatable {
  case online
  case offline
}

public protocol MarketClockService: Sendable {
  var events: AsyncStream<MarketClockEvent> { get }
  func currentSession(now: Date) -> MarketSession?
}

public protocol BrokerAuthService: Sendable {
  var states: AsyncStream<BrokerAuthState> { get }
}

public protocol ConnectivityService: Sendable {
  var states: AsyncStream<ConnectivityState> { get }
}

public protocol Notifier: Sendable {
  func requestAuthorizationIfNeeded() async
  func post(title: String, body: String, category: String?) async
}

public struct NotificationRule: Sendable, Equatable {
  public var openThresholds: [Int]
  public var closeThresholds: [Int]
  public init(
    openThresholds: [Int] = [60, 30, 10, 5, 1], closeThresholds: [Int] = [60, 30, 10, 5, 1]
  ) {
    self.openThresholds = openThresholds.sorted(by: >)
    self.closeThresholds = closeThresholds.sorted(by: >)
  }
}
