import SwiftUI

struct AdminInfraView: View {
    @State private var resources: [InfraResource] = []
    @State private var loading = true
    @State private var error = ""
    @State private var message = ""
    var body: some View {
        NavigationStack {
            List {
                if !message.isEmpty { Section { Text(message).font(.system(size: 12)).foregroundStyle(Brand.gold) } }
                if !error.isEmpty { Section { Text(error).foregroundStyle(Brand.danger) } }
                Section("Coolify") {
                    ForEach(resources) { r in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack { VStack(alignment: .leading) { Text(r.name).font(.system(size: 13, weight: .semibold)); Text(r.type.uppercased()).font(.system(size: 9)).foregroundStyle(Brand.muted) }; Spacer(); Text(r.status).font(.system(size: 9)).foregroundStyle(r.status.contains("running") ? Brand.gold : Brand.danger) }
                            HStack(spacing: 8) {
                                Button("Redémarrer") { Task { await act(r, "restart") } }.buttonStyle(.bordered)
                                Button("Déployer") { Task { await act(r, "deploy") } }.buttonStyle(.borderedProminent)
                            }.font(.system(size: 11))
                        }.padding(.vertical, 4)
                    }
                }
                if loading { ProgressView() }
            }.navigationTitle("Infrastructure").refreshable { await load() }.task { await load() }
        }
    }
    func load() async {
        do { resources = try await AdminAPI.shared.infra() }
        catch let e { error = e.localizedDescription }
        loading = false
    }
    func act(_ r: InfraResource, _ action: String) async {
        message = "\(action == "deploy" ? "Déploiement" : "Redémarrage") de \(r.name)…"
        do { try await AdminAPI.shared.infraAction(uuid: r.id, type: r.type, action: action); message = "Action lancée sur \(r.name)."; try? await Task.sleep(nanoseconds: 2_000_000_000); await load() }
        catch let e { error = e.localizedDescription }
    }
}
