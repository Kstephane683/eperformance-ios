import SwiftUI

struct AdminProgramsView: View {
    @State private var programs: [Program] = []
    @State private var error = ""
    @State private var message = ""
    @State private var selected: Program?
    @State private var planTitle = "Plan acquisition 30 jours"
    @State private var tasks = "1 | Rassembler les chiffres\n1 | Identifier la fuite principale\n2 | Créer la relance\n2 | Tester sur 10 prospects\n3 | Ajuster la campagne\n3 | Former l’équipe\n4 | Comparer les résultats\n4 | Décider du prochain cycle"
    @State private var bonusTitle = "Votre ebook bonus"
    @State private var bonusURL = ""
    var body: some View {
        List {
            if !message.isEmpty { Text(message).font(.system(size: 12)).foregroundStyle(Brand.gold) }
            if !error.isEmpty { Text(error).font(.system(size: 12)).foregroundStyle(Brand.danger) }
            ForEach(programs) { p in
                VStack(alignment: .leading, spacing: 8) {
                    Text(p.name).font(.system(size: 14, weight: .semibold))
                    Text("\(p.email) · \(p.type.uppercased()) · \(p.priceXof) FCFA").font(.system(size: 11)).foregroundStyle(Brand.muted)
                    Text(p.accessStatus).font(.system(size: 10)).foregroundStyle(Brand.gold)
                    HStack {
                        Button("Second formulaire") { Task { await act(p, "second_form") } }.buttonStyle(.bordered)
                        Button("Plan") { selected = p }.buttonStyle(.bordered)
                    }.font(.system(size: 11))
                }.padding(.vertical, 4)
            }
        }.navigationTitle("Programmes").task { await load() }
        .sheet(item: $selected) { p in
            NavigationStack {
                Form {
                    Section("Plan pour \(p.name)") {
                        TextField("Titre", text: $planTitle)
                        TextField("Semaine | action, une par ligne", text: $tasks, axis: .vertical).lineLimit(5...12)
                        Button("Publier le plan") { Task { await plan(p) } }
                    }
                    Section("Bonus") {
                        TextField("Titre", text: $bonusTitle)
                        TextField("URL du PDF", text: $bonusURL).keyboardType(.URL).autocapitalization(.none)
                        Button("Livrer le bonus") { Task { await bonus(p) } }.disabled(bonusURL.isEmpty)
                    }
                }.navigationTitle("Programme").toolbar { Button("Fermer") { selected = nil } }
            }
        }
    }
    func load() async {
        do { programs = try await AdminAPI.shared.programs() }
        catch let e { error = e.localizedDescription }
    }
    func act(_ p: Program, _ action: String) async {
        do { try await AdminAPI.shared.programAction(["action": action, "programId": p.id]); message = "Action effectuée."; await load() }
        catch let e { error = e.localizedDescription }
    }
    func plan(_ p: Program) async {
        do { try await AdminAPI.shared.programAction(["action":"create_plan","programId":p.id,"title":planTitle,"tasks":tasks]); message = "Plan publié."; selected = nil }
        catch let e { error = e.localizedDescription }
    }
    func bonus(_ p: Program) async {
        do { try await AdminAPI.shared.programAction(["action":"bonus","programId":p.id,"title":bonusTitle,"url":bonusURL]); message = "Bonus livré."; selected = nil }
        catch let e { error = e.localizedDescription }
    }
}
