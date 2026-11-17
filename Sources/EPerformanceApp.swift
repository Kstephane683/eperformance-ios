import SwiftUI

@main
struct EPerformanceApp: App {
    @StateObject private var session = SessionStore()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
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
}
