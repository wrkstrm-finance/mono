import Foundation
import UserNotifications

public final class LocalUserNotifier: Notifier {
  public init() {}

  public func requestAuthorizationIfNeeded() async {
    let center = UNUserNotificationCenter.current()
    let settings = await center.notificationSettings()
    if settings.authorizationStatus == .notDetermined {
      _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }
    await registerDefaultCategories()
  }

  public func post(title: String, body: String, category: String?) async {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    if let category { content.categoryIdentifier = category }
    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: nil
    )
    do { try await UNUserNotificationCenter.current().add(request) } catch {}
  }

  private func registerDefaultCategories() async {
    let center = UNUserNotificationCenter.current()
    let openTau = UNNotificationAction(
      identifier: "OPEN_TAU",
      title: "Open Tau",
      options: [.foreground]
    )
    let reauth = UNNotificationAction(
      identifier: "REAUTH",
      title: "Re‑authenticate",
      options: [.foreground]
    )
    let market = UNNotificationCategory(
      identifier: "market",
      actions: [openTau],
      intentIdentifiers: [], options: []
    )
    let auth = UNNotificationCategory(
      identifier: "auth",
      actions: [reauth],
      intentIdentifiers: [], options: []
    )
    center.setNotificationCategories([market, auth])
  }
}
