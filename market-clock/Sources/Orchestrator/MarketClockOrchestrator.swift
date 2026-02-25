import Foundation

@MainActor
public final class MarketClockOrchestrator {
  private let clock: MarketClockService
  private let auth: BrokerAuthService
  private let net: ConnectivityService
  private let rules: NotificationRule
  private let notifier: Notifier

  private var task: Task<Void, Never>?
  private var netTask: Task<Void, Never>?
  private var lastConnectivity: ConnectivityState?
  private var connectivityDebounceTask: Task<Void, Never>?
  private let suppressor = NotificationSuppressor()

  public init(
    clock: MarketClockService,
    auth: BrokerAuthService,
    net: ConnectivityService,
    rules: NotificationRule = .init(),
    notifier: Notifier
  ) {
    self.clock = clock
    self.auth = auth
    self.net = net
    self.rules = rules
    self.notifier = notifier
  }

  public func start() {
    task?.cancel()
    netTask?.cancel()
    task = Task { [clock, auth, net, rules, notifier] in
      await notifier.requestAuthorizationIfNeeded()
      let authStates = auth.states
      let netStates = net.states
      let events = clock.events
      var currentAuth: BrokerAuthState = .authorized
      var currentNet: ConnectivityState = .online

      let authIter = Task {
        for await s in authStates {
          currentAuth = s
          if s == .unauthorized {
            if await suppressor.allow(key: "auth-required", within: 300) {
              await notifier.post(
                title: "Authorization required", body: "Sign in to receive trading alerts",
                category: "auth")
            }
          }
        }
      }
      let netIter = Task {
        for await s in netStates {
          currentNet = s
          await self.handleConnectivityChange(s)
        }
      }

      for await event in events where currentAuth == .authorized {
        guard currentNet == .online else { continue }
        switch event {
        case .opensIn(let m):
          if rules.openThresholds.contains(m) {
            if await suppressor.allow(key: "market-open-\(m)", within: 90) {
              await notifier.post(
                title: "Market opens soon", body: "Opens in \(m)m", category: "market")
            }
          }
        case .closesIn(let m):
          if rules.closeThresholds.contains(m) {
            if await suppressor.allow(key: "market-close-\(m)", within: 90) {
              await notifier.post(
                title: "Market closes soon", body: "Closes in \(m)m", category: "market")
            }
          }
        case .opened:
          if await suppressor.allow(key: "market-opened", within: 300) {
            await notifier.post(
              title: "Market opened", body: "Regular session is now open", category: "market")
          }
        case .closed:
          if await suppressor.allow(key: "market-closed", within: 300) {
            await notifier.post(
              title: "Market closed", body: "Regular session is now closed", category: "market")
          }
        }
      }
      _ = authIter
      _ = netIter
    }
  }

  public func stop() {
    task?.cancel()
    netTask?.cancel()
  }

  @MainActor private func handleConnectivityChange(_ new: ConnectivityState) async {
    // Debounce flaps for 2 seconds
    connectivityDebounceTask?.cancel()
    let current = new
    connectivityDebounceTask = Task { [weak self] in
      try? await Task.sleep(nanoseconds: 2_000_000_000)
      guard let self else { return }
      if self.lastConnectivity != current {
        self.lastConnectivity = current
        switch current {
        case .offline:
          if await suppressor.allow(key: "net-offline", within: 120) {
            await notifier.post(
              title: "Connectivity lost", body: "Trading alerts paused while offline",
              category: "net")
          }
        case .online:
          if await suppressor.allow(key: "net-online", within: 120) {
            await notifier.post(
              title: "Connectivity restored", body: "Trading alerts resumed", category: "net")
          }
        }
      }
    }
  }
}

// MARK: - Notification suppressor

actor NotificationSuppressor {
  private var last: [String: Date] = [:]

  func allow(key: String, within seconds: TimeInterval) -> Bool {
    let now = Date()
    if let prev = last[key], now.timeIntervalSince(prev) < seconds { return false }
    last[key] = now
    return true
  }
}
