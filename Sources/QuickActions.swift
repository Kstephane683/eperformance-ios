import SwiftUI
import UIKit

extension Notification.Name {
    static let epQuickAction = Notification.Name("epQuickAction")
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        if let shortcut = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                NotificationCenter.default.post(name: .epQuickAction, object: shortcut.type)
            }
        }
        return true
    }
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        NotificationCenter.default.post(name: .epQuickAction, object: shortcutItem.type)
        completionHandler(true)
    }
}
