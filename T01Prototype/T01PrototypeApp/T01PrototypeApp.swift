import SwiftUI
import UserNotifications

final class NotificationPresentationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationPresentationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
                                @escaping (UNNotificationPresentationOptions) -> Void) {
        let options: UNNotificationPresentationOptions = notification.request.content.sound == nil
            ? [.banner, .list]
            : [.banner, .list, .sound]
        completionHandler(options)
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
