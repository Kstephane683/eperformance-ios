import SwiftUI
import UserNotifications

@main
struct EPerformanceAdminApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var session = AdminSession()
    @StateObject private var notifications = NotificationManager()
    var body: some Scene {
        WindowGroup {
            AdminRootView()
                .environmentObject(session)
                .environmentObject(notifications)
                .tint(Brand.gold)
                .preferredColorScheme(.light)
        }
    }
}

enum Brand {
    static let ink = Color(red: 0.09, green: 0.08, blue: 0.11)
    static let cream = Color(red: 0.97, green: 0.95, blue: 0.92)
    static let paper = Color(red: 1.0, green: 0.99, blue: 0.97)
    static let gold = Color(red: 0.79, green: 0.66, blue: 0.43)
    static let muted = Color(red: 0.45, green: 0.43, blue: 0.39)
    static let line = Color(red: 0.90, green: 0.87, blue: 0.81)
    static let danger = Color(red: 0.62, green: 0.20, blue: 0.18)
}

final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var authorized = false
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { self.authorized = granted }
        }
    }
    func notify(title: String, body: String) {
        guard authorized else { return }
        let content = UNMutableNotificationContent()
        content.title = title; content.body = body; content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
