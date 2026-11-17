import Foundation

struct APIError: LocalizedError { let message: String; var errorDescription: String? { message } }

struct AdminOverview: Decodable {
    let ok: Bool
    let admin: AdminInfo
    let stats: Stats
    let leads: [Lead]
    let diagnostics: [Diagnostic]
    let appointments: [Appointment]
    let payments: [Payment]
}
struct AdminInfo: Decodable { let name: String; let email: String }
struct Stats: Decodable { let leads: Int; let diagnostics: Int; let appointments: Int; let payments: Int; let reports: Int }
struct Lead: Decodable, Identifiable {
    let id: String; let name: String; let company: String?; let email: String; let whatsapp: String?; let source: String; let segment: String; let message: String?; let status: String; let createdAt: String?
}
struct Diagnostic: Decodable, Identifiable {
    let id: String; let name: String; let email: String; let businessType: String; let priority: String?; let status: String; let createdAt: String?
}
struct Appointment: Decodable, Identifiable {
    let id: String; let name: String; let email: String; let whatsapp: String?; let preferredAt: String?; let message: String?; let status: String; let createdAt: String?
}
struct Payment: Decodable, Identifiable { let id: String; let amountXof: Int; let status: String; let email: String?; let createdAt: String? }
struct Program: Decodable, Identifiable { let id: String; let email: String; let name: String; let type: String; let priceXof: Int; let accessStatus: String }
struct ProgramsResponse: Decodable { let ok: Bool; let programs: [Program] }
struct InfraResource: Decodable, Identifiable { let id: String; let name: String; let type: String; let status: String; let url: String? }
struct InfraResponse: Decodable { let ok: Bool; let resources: [InfraResource] }

final class AdminAPI {
    static let shared = AdminAPI()
    let baseURL = URL(string: "https://app.eperformance.pro")!
    private let session: URLSession
    init() {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        session = URLSession(configuration: config)
    }
    func requestCode(email: String) async throws {
        _ = try await post("/api/auth/request-code", body: ["email": email, "name": "Admin ePerformance", "activityType": "pme"])
    }
    func verify(email: String, code: String) async throws -> String {
        let data = try await post("/api/auth/verify-code", body: ["email": email, "code": code])
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let role = object?["role"] as? String, role == "admin" else { throw APIError(message: "Ce compte n’est pas administrateur.") }
        return role
    }
    func assistant(leadId: String) async throws -> (String, String) {
        let data = try await post("/api/admin/lead-assistant", body: ["leadId": leadId])
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return (object?["summary"] as? String ?? "", object?["draft"] as? String ?? "")
    }
    func message(leadId: String, channel: String, body: String, send: Bool) async throws -> String {
        let data = try await post("/api/admin/messages", body: ["leadId": leadId, "channel": channel, "body": body, "action": send ? "send" : "draft"])
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return object?["status"] as? String ?? "draft"
    }
    func performAction(_ body: [String: Any]) async throws {
        _ = try await post("/api/admin/actions", body: body)
    }
    func programs() async throws -> [Program] {
        var request = URLRequest(url: URL(string: "/api/admin/programs", relativeTo: baseURL)!)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw APIError(message: "Programmes indisponibles.") }
        return try JSONDecoder().decode(ProgramsResponse.self, from: data).programs
    }
    func programAction(_ body: [String: Any]) async throws {
        _ = try await post("/api/admin/programs", body: body)
    }
    func infra() async throws -> [InfraResource] {
        var request = URLRequest(url: URL(string: "/api/admin/infra", relativeTo: baseURL)!)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw APIError(message: "Coolify indisponible.") }
        let decoder = JSONDecoder()
        return try decoder.decode(InfraResponse.self, from: data).resources
    }
    func infraAction(uuid: String, type: String, action: String) async throws {
        _ = try await post("/api/admin/infra", body: ["uuid": uuid, "type": type, "action": action])
    }
    func overview() async throws -> AdminOverview {
        var request = URLRequest(url: URL(string: "/api/admin/overview", relativeTo: baseURL)!)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw APIError(message: "Accès admin refusé.") }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(AdminOverview.self, from: data)
    }
    func logout() async { _ = try? await post("/api/auth/logout", body: [:]) }
    private func post(_ path: String, body: [String: Any]) async throws -> Data {
        var request = URLRequest(url: URL(string: path, relativeTo: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError(message: "Réponse invalide.") }
        guard (200...299).contains(http.statusCode) else {
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            throw APIError(message: (object?["error"] as? String) ?? "Erreur \(http.statusCode).")
        }
        return data
    }
}

@MainActor
final class AdminSession: ObservableObject {
    @Published var isAdmin = false
    @Published var email = ""
    @Published var name = "Admin"
    init() {
        isAdmin = UserDefaults.standard.bool(forKey: "ep_admin")
        email = UserDefaults.standard.string(forKey: "ep_admin_email") ?? ""
        name = UserDefaults.standard.string(forKey: "ep_admin_name") ?? "Admin"
    }
    func signIn(email: String, name: String) {
        self.email = email; self.name = name; isAdmin = true
        UserDefaults.standard.set(true, forKey: "ep_admin")
        UserDefaults.standard.set(email, forKey: "ep_admin_email")
        UserDefaults.standard.set(name, forKey: "ep_admin_name")
    }
    func signOut() {
        isAdmin = false
        UserDefaults.standard.set(false, forKey: "ep_admin")
        Task { await AdminAPI.shared.logout() }
    }
}
