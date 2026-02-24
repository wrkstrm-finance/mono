import Foundation

public final class FakeMarketClockService: MarketClockService {
  public let events: AsyncStream<MarketClockEvent>
  private let continuation: AsyncStream<MarketClockEvent>.Continuation
  private var task: Task<Void, Never>?

  public init(rules: NotificationRule = .init()) {
    var cont: AsyncStream<MarketClockEvent>.Continuation!
    self.events = AsyncStream<MarketClockEvent> { c in cont = c }
    self.continuation = cont
    startEmitting(rules: rules)
  }

  deinit { task?.cancel() }

  public func currentSession(now: Date = .init()) -> MarketSession? {
    let tz = TimeZone(identifier: "America/New_York") ?? .init(secondsFromGMT: -5 * 3600)!
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = tz
    guard let start = cal.date(bySettingHour: 9, minute: 30, second: 0, of: now),
      let end = cal.date(bySettingHour: 16, minute: 0, second: 0, of: now)
    else { return nil }
    return .init(start: start, end: end, kind: .regular, timeZone: tz)
  }

  private func startEmitting(rules: NotificationRule) {
    task = Task { [continuation] in
      var lastEmittedOpen: Set<Int> = []
      var lastEmittedClose: Set<Int> = []
      var openedEmitted = false
      var closedEmitted = false
      while !Task.isCancelled {
        let now = Date()
        if let session = currentSession(now: now) {
          let minutesToOpen = Int((session.start.timeIntervalSince(now) / 60).rounded(.down))
          let minutesToClose = Int((session.end.timeIntervalSince(now) / 60).rounded(.down))

          if minutesToOpen > 0 {
            openedEmitted = false
            for m in rules.openThresholds
            where m >= 0 && minutesToOpen == m && !lastEmittedOpen.contains(m) {
              continuation.yield(.opensIn(minutes: m))
              lastEmittedOpen.insert(m)
            }
          } else if minutesToOpen <= 0 && !openedEmitted && now < session.end {
            continuation.yield(.opened)
            openedEmitted = true
            lastEmittedOpen.removeAll()
          }

          if minutesToClose > 0 {
            closedEmitted = false
            for m in rules.closeThresholds
            where m >= 0 && minutesToClose == m && !lastEmittedClose.contains(m) {
              continuation.yield(.closesIn(minutes: m))
              lastEmittedClose.insert(m)
            }
          } else if minutesToClose <= 0 && !closedEmitted {
            continuation.yield(.closed)
            closedEmitted = true
            lastEmittedClose.removeAll()
          }
        }
        try? await Task.sleep(nanoseconds: 60 * 1_000_000_000)
      }
    }
  }
}

// Concurrency: events are delivered on an internal Task; the type is not Sendable-safe but
// MarketClockService does not require cross-actor mutation. Mark unchecked for Swift 6.
extension FakeMarketClockService: @unchecked Sendable {}
