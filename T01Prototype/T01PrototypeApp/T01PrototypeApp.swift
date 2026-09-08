import SwiftUI
import UserNotifications

final class NotificationPresentationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationPresentationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
                                @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(Self.presentationOptions(for: notification.request.content))
    }

    static func presentationOptions(for content: UNNotificationContent)
        -> UNNotificationPresentationOptions {
        content.sound == nil
            ? [.banner, .list]
            : [.banner, .list, .sound]
    }
}

@main
struct T01PrototypeApp: App {
    init() {
        UNUserNotificationCenter.current().delegate = NotificationPresentationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
