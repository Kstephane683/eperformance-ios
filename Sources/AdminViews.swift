import SwiftUI
import UIKit

struct AdminRootView: View {
    @EnvironmentObject var session: AdminSession
    var body: some View {
        Group { session.isAdmin ? AnyView(AdminTabs()) : AnyView(AdminLoginView()) }
            .background(Brand.cream.ignoresSafeArea())
    }
}

struct AdminLoginView: View {
    @EnvironmentObject var session: AdminSession
    @State private var email = "kstephane683@gmail.com"
    @State private var code = ""
    @State private var sent = false
    @State private var busy = false
    @State private var error = ""
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                BrandMark().padding(.top, 40)
                Text("ADMINISTRATION").font(.system(size: 10, weight: .bold)).tracking(2).foregroundStyle(Brand.gold)
                Text("Reprendre\nla main.").font(.system(size: 46, weight: .semibold, design: .serif)).foregroundStyle(Brand.ink)
                Text("Console privée ePerformance. Seuls les comptes administrateurs peuvent entrer.").font(.system(size: 14)).foregroundStyle(Brand.muted)
                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        FieldLabel(text: "Email administrateur")
                        TextField("kstephane683@gmail.com", text: $email).textFieldStyle(.roundedBorder).keyboardType(.emailAddress).autocapitalization(.none).textContentType(.emailAddress)
                        if !sent {
                            PrimaryButton(title: busy ? "Envoi…" : "Recevoir mon code", disabled: busy || email.isEmpty) {
                                Task {
                                    busy = true; error = ""
                                    do { try await AdminAPI.shared.requestCode(email: email); sent = true }
                                    catch let err { error = err.localizedDescription }
                                    busy = false
                                }
                            }
                        } else {
                            Text("Code envoyé à \(email). Vérifie Gmail et les spams.").font(.system(size: 12)).foregroundStyle(Brand.muted)
                            FieldLabel(text: "Code à 6 chiffres")
                            TextField("000000", text: $code).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                            PrimaryButton(title: busy ? "Vérification…" : "Entrer dans l’admin", disabled: busy || code.count < 6) {
                                Task {
                                    busy = true; error = ""
                                    do { _ = try await AdminAPI.shared.verify(email: email, code: code); session.signIn(email: email, name: "K. Stéphane") }
                                    catch let err { error = err.localizedDescription }
                                    busy = false
                                }
                            }
                            Button("Changer d’email") { sent = false; code = "" }.font(.system(size: 12)).foregroundStyle(Brand.muted)
                        }
                        if !error.isEmpty { Text(error).font(.system(size: 12)).foregroundStyle(Brand.danger) }
                    }
                }
                Text("Pas de compte client ici. Cette app est réservée à l’administration ePerformance.").font(.system(size: 11)).foregroundStyle(Brand.muted)
            }.padding(24).frame(maxWidth: 560)
        }
    }
}

struct AdminTabs: View {
    @State private var tab = 0
    var body: some View {
        TabView(selection: $tab) {
            AdminOverviewView().tabItem { Label("Vue", systemImage: "square.grid.2x2") }.tag(0)
            AdminInboxView().tabItem { Label("Entrants", systemImage: "tray.full") }.tag(1)
            AdminAgendaView().tabItem { Label("Agenda", systemImage: "calendar") }.tag(2)
            AdminInfraView().tabItem { Label("Infra", systemImage: "server.rack") }.tag(3)
            AdminMoreView().tabItem { Label("Plus", systemImage: "ellipsis.circle") }.tag(4)
        }
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onReceive(NotificationCenter.default.publisher(for: .epQuickAction)) { note in
            if let type = note.object as? String {
                switch type {
                case "leads", "diagnostics": tab = 1
                case "agenda": tab = 2
                case "site": UIApplication.shared.open(URL(string: "https://eperformance.pro")!)
                default: tab = 0
                }
            }
        }
    }
}

struct AdminOverviewView: View {
    @EnvironmentObject var session: AdminSession
    @EnvironmentObject var notifications: NotificationManager
    @State private var overview: AdminOverview?
    @State private var loading = true
    @State private var error = ""
    @State private var lastLeads = UserDefaults.standard.integer(forKey: "last_lead_count")
    @State private var banner = ""
    @State private var showNotifications = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack { BrandMark(); Spacer()
                        Button { showNotifications = true } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell").font(.system(size: 17, weight: .semibold)).foregroundStyle(Brand.ink)
                                if let o = overview, o.stats.leads + o.stats.appointments > 0 {
                                    Text("\(min(o.stats.leads + o.stats.appointments, 9))").font(.system(size: 8, weight: .bold)).foregroundStyle(.white).frame(width: 15, height: 15).background(Brand.danger).clipShape(Circle())
                                }
                            }.padding(11).background(.ultraThinMaterial, in: Circle()).overlay(Circle().stroke(.white.opacity(0.5)))
                        }
                        Text("ADMIN").font(.system(size: 9, weight: .bold)).tracking(1.5).foregroundStyle(Brand.gold) }
                    SectionTitle(eyebrow: "Administration", title: "Vue d’ensemble.")
                    if !banner.isEmpty { Text(banner).font(.system(size: 12, weight: .semibold)).foregroundStyle(Brand.ink).padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Brand.gold.opacity(0.25)).clipShape(RoundedRectangle(cornerRadius: 12)) }
                    if loading { ProgressView().padding() } else if let o = overview {
                        HStack(spacing: 10) {
                            Metric(value: "\(o.stats.leads)", label: "Leads")
                            Metric(value: "\(o.stats.diagnostics)", label: "Diagnostics")
                        }
                        HStack(spacing: 10) {
                            Metric(value: "\(o.stats.appointments)", label: "RDV")
                            Metric(value: "\(o.stats.payments)", label: "Payés")
                        }
                        Card { VStack(alignment: .leading, spacing: 10) { Text("Derniers entrants").font(.system(size: 13, weight: .semibold)); ForEach(o.leads.prefix(4)) { lead in HStack { VStack(alignment: .leading) { Text(lead.name).font(.system(size: 13, weight: .semibold)); Text("\(lead.source) · \(lead.segment.uppercased())").font(.system(size: 10)).foregroundStyle(Brand.muted) }; Spacer(); Text(lead.status).font(.system(size: 9)).foregroundStyle(Brand.gold) } } } }
                        Card { VStack(alignment: .leading, spacing: 10) { Text("Rendez-vous").font(.system(size: 13, weight: .semibold)); if o.appointments.isEmpty { Text("Aucune demande.").font(.system(size: 12)).foregroundStyle(Brand.muted) } else { ForEach(o.appointments.prefix(4)) { a in HStack { Text(a.name).font(.system(size: 13)); Spacer(); Text(a.status).font(.system(size: 9)).foregroundStyle(Brand.gold) } } } } }
                    } else { Text(error.isEmpty ? "Chargement…" : error).foregroundStyle(Brand.danger).font(.system(size: 12)) }
                }.padding(20)
            }.background(Brand.cream.ignoresSafeArea()).refreshable { await load() }
            .sheet(isPresented: $showNotifications) { AdminNotificationsSheet(overview: overview) }
            .task { await poll() }
        }
    }
    func load() async {
        do { let o = try await AdminAPI.shared.overview(); overview = o; loading = false; check(o) }
        catch let err { error = err.localizedDescription; loading = false }
    }
    func poll() async {
        await load()
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            await load()
        }
    }
    func check(_ o: AdminOverview) {
        if lastLeads > 0 && o.stats.leads > lastLeads {
            let delta = o.stats.leads - lastLeads
            banner = "\(delta) nouveau\(delta > 1 ? "x" : "") contact\(delta > 1 ? "s" : "")"
            notifications.notify(title: "ePerformance Admin", body: banner)
        }
        lastLeads = o.stats.leads
        UserDefaults.standard.set(lastLeads, forKey: "last_lead_count")
    }
}

struct AdminNotificationsSheet: View {
    let overview: AdminOverview?
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("Nouveaux contacts") {
                    if let o = overview, !o.leads.isEmpty { ForEach(o.leads.prefix(6)) { l in VStack(alignment: .leading) { Text(l.name).font(.system(size: 13, weight: .semibold)); Text("\(l.source) · \(l.company ?? l.email)").font(.system(size: 11)).foregroundStyle(Brand.muted) } } } else { Text("Aucun nouveau contact.").foregroundStyle(Brand.muted) }
                }
                Section("Rendez-vous") {
                    if let o = overview, !o.appointments.isEmpty { ForEach(o.appointments.prefix(6)) { a in VStack(alignment: .leading) { Text(a.name).font(.system(size: 13, weight: .semibold)); Text(a.preferredAt ?? "Créneau à confirmer").font(.system(size: 11)).foregroundStyle(Brand.muted) } } } else { Text("Aucune demande.").foregroundStyle(Brand.muted) }
                }
            }.navigationTitle("Notifications").toolbar { Button("Fermer") { dismiss() } }
        }
    }
}

struct Metric: View {
    let value: String; let label: String
    var body: some View { VStack(alignment: .leading, spacing: 4) { Text(value).font(.system(size: 30, weight: .semibold, design: .serif)); Text(label.uppercased()).font(.system(size: 9, weight: .bold)).tracking(1.2).foregroundStyle(Brand.muted) }.padding(15).frame(maxWidth: .infinity, alignment: .leading).background(Brand.paper).overlay(RoundedRectangle(cornerRadius: 15).stroke(Brand.line)).clipShape(RoundedRectangle(cornerRadius: 15)) }
}

struct AdminInboxView: View {
    @State private var overview: AdminOverview?
    @State private var error = ""
    var body: some View {
        NavigationStack {
            List {
                if let o = overview {
                    Section("Contacts") {
                        ForEach(o.leads) { lead in
                            NavigationLink {
                                LeadDetailView(lead: lead)
                            } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack { Text(lead.name).font(.system(size: 14, weight: .semibold)); Spacer(); Text(lead.status).font(.system(size: 9)).foregroundStyle(Brand.gold) }
                                    Text("\(lead.company ?? "") · \(lead.email)").font(.system(size: 11)).foregroundStyle(Brand.muted)
                                    if let m = lead.message { Text(m).font(.system(size: 12)).lineLimit(2) }
                                }
                            }
                        }
                    }
                    Section("Diagnostics") {
                        ForEach(o.diagnostics) { d in
                            NavigationLink {
                                DiagnosticDetailView(diagnostic: d)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(d.name).font(.system(size: 13, weight: .semibold))
                                        Text("\(d.businessType.uppercased()) · \(d.priority ?? "—")").font(.system(size: 10)).foregroundStyle(Brand.muted)
                                    }
                                    Spacer()
                                    Text(d.status).font(.system(size: 9)).foregroundStyle(Brand.gold)
                                }
                            }
                        }
                    }
                } else { Text(error).foregroundStyle(Brand.danger) }
            }
            .navigationTitle("Entrants")
            .task { do { overview = try await AdminAPI.shared.overview() } catch let e { error = e.localizedDescription } }
        }
    }
}

struct AdminAgendaView: View {
    @State private var overview: AdminOverview?
    @State private var error = ""
    var body: some View {
        NavigationStack {
            List {
                if let o = overview {
                    ForEach(o.appointments) { a in
                        NavigationLink {
                            AppointmentDetailView(appointment: a)
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack { Text(a.name).font(.system(size: 14, weight: .semibold)); Spacer(); Text(a.status).font(.system(size: 9)).foregroundStyle(Brand.gold) }
                                Text("\(a.email) · \(a.whatsapp ?? "")").font(.system(size: 11)).foregroundStyle(Brand.muted)
                                Text(a.preferredAt ?? "Créneau à confirmer").font(.system(size: 11))
                                if let m = a.message { Text(m).font(.system(size: 12)).lineLimit(2) }
                            }
                        }
                    }
                } else { Text(error).foregroundStyle(Brand.danger) }
            }
            .navigationTitle("Agenda")
            .task { do { overview = try await AdminAPI.shared.overview() } catch let e { error = e.localizedDescription } }
        }
    }
}

struct AdminMoreView: View {
    @EnvironmentObject var session: AdminSession
    @EnvironmentObject var notifications: NotificationManager
    @State private var overview: AdminOverview?
    @State private var error = ""
    var body: some View {
        NavigationStack { List {
            Section("Compte") { LabeledContent("Admin", value: session.email); LabeledContent("Notifications", value: notifications.authorized ? "Activées" : "Désactivées"); LabeledContent("Version", value: "1.0.3") }
            Section("Paiements récents") { if let o = overview { ForEach(o.payments.prefix(8)) { p in HStack { Text(p.email ?? "—").font(.system(size: 12)); Spacer(); Text("\(p.amountXof) FCFA").font(.system(size: 11)); Text(p.status).font(.system(size: 9)).foregroundStyle(p.status == "paid" ? Brand.gold : Brand.muted) } } } else { Text("Chargement…").foregroundStyle(Brand.muted) } }
            Section("Accompagnement") { NavigationLink("Programmes et plans", destination: AdminProgramsView()) }
            Section("Liens") { Link("Site ePerformance", destination: URL(string: "https://eperformance.pro")!); Link("Espace client web", destination: URL(string: "https://app.eperformance.pro/admin")!); Link("Cal.com", destination: URL(string: "https://cal.eperformance.pro/auth/login")!) }
            Section { Button("Se déconnecter", role: .destructive) { session.signOut() } }
        }.navigationTitle("Plus").task { do { overview = try await AdminAPI.shared.overview() } catch let e { error = e.localizedDescription } } }
    }
}
