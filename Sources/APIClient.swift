import Foundation

struct APIError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

final class APIClient {
    static let shared = APIClient()
    let baseURL = URL(string: "https://app.eperformance.pro")!
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        session = URLSession(configuration: config)
    }

    func requestCode(email: String, name: String, activityType: String) async throws {
        try await post(path: "/api/auth/request-code", body: [
            "email": email,
            "name": name,
            "activityType": activityType
        ])
    }

    func verifyCode(email: String, code: String) async throws -> String {
        let data = try await post(path: "/api/auth/verify-code", body: ["email": email, "code": code])
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return object?["role"] as? String ?? "client"
    }

    func submitDiagnostic(_ body: [String: Any]) async throws {
        _ = try await post(path: "/api/diagnostic", body: body)
    }

    func submitContact(_ body: [String: Any]) async throws {
        _ = try await post(path: "/api/leads", body: body)
    }

    func requestAppointment(_ body: [String: Any]) async throws {
        _ = try await post(path: "/api/appointments", body: body)
    }

    func logout() async {
        _ = try? await post(path: "/api/auth/logout", body: [:])
    }

    @discardableResult
    private func post(path: String, body: [String: Any]) async throws -> Data {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError(message: "Réponse invalide.") }
        guard (200...299).contains(http.statusCode) else {
            let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
            throw APIError(message: message ?? "Erreur \(http.statusCode).")
        }
        return data
    }
}

@MainActor
final class SessionStore: ObservableObject {
    @Published var isAuthenticated = false
    @Published var role = "client"
    @Published var email = ""
    @Published var name = ""

    init() {
        if let saved = UserDefaults.standard.string(forKey: "ep_email"), !saved.isEmpty {
            email = saved
            isAuthenticated = UserDefaults.standard.bool(forKey: "ep_auth")
            role = UserDefaults.standard.string(forKey: "ep_role") ?? "client"
            name = UserDefaults.standard.string(forKey: "ep_name") ?? ""
        }
    }

    func signIn(email: String, name: String, role: String) {
        self.email = email; self.name = name; self.role = role; isAuthenticated = true
        UserDefaults.standard.set(true, forKey: "ep_auth")
        UserDefaults.standard.set(email, forKey: "ep_email")
        UserDefaults.standard.set(name, forKey: "ep_name")
        UserDefaults.standard.set(role, forKey: "ep_role")
    }

    func signOut() {
        isAuthenticated = false; role = "client"
        UserDefaults.standard.set(false, forKey: "ep_auth")
        Task { await APIClient.shared.logout() }
    }
}
