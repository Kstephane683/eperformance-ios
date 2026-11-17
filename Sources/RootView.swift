import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: SessionStore
    var body: some View {
        Group { if session.isAuthenticated { MainTabView() } else { LoginView() } }
            .background(Brand.cream.ignoresSafeArea())
    }
}

struct LoginView: View {
    @EnvironmentObject var session: SessionStore
    @State private var email = ""
    @State private var name = ""
    @State private var code = ""
    @State private var codeSent = false
    @State private var busy = false
    @State private var error = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                BrandMark().padding(.top, 28)
                Text("Votre acquisition,\nEnfin lisible.").font(.system(size: 42, weight: .semibold, design: .serif)).foregroundStyle(Brand.ink)
                Text("Connectez-vous à votre espace ePerformance. Le code vous est envoyé par email.").font(.system(size: 14)).foregroundStyle(Brand.muted)
                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        if !codeSent {
                            FieldLabel(text: "Nom")
                            TextField("Votre nom", text: $name).textFieldStyle(.roundedBorder).textContentType(.name)
                            FieldLabel(text: "Email")
                            TextField("vous@exemple.com", text: $email).textFieldStyle(.roundedBorder).textContentType(.emailAddress).keyboardType(.emailAddress).autocapitalization(.none)
                            PrimaryButton(title: busy ? "Envoi…" : "Recevoir mon code", disabled: busy || email.isEmpty) {
                                Task {
                                    busy = true; error = ""
                                    do { try await APIClient.shared.requestCode(email: email, name: name, activityType: "pme"); codeSent = true }
                                    catch let err { error = err.localizedDescription }
                                    busy = false
                                }
                            }
                        } else {
                            Text("Code envoyé à \(email)").font(.system(size: 13)).foregroundStyle(Brand.muted)
                            FieldLabel(text: "Code à 6 chiffres")
                            TextField("000000", text: $code).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                            PrimaryButton(title: busy ? "Vérification…" : "Ouvrir mon espace", disabled: busy || code.count < 6) {
                                Task {
                                    busy = true; error = ""
                                    do { let role = try await APIClient.shared.verifyCode(email: email, code: code); session.signIn(email: email, name: name, role: role) }
                                    catch let err { error = err.localizedDescription }
                                    busy = false
                                }
                            }
                            Button("Renvoyer le code") { codeSent = false }.font(.system(size: 12)).foregroundStyle(Brand.muted)
                        }
                        if !error.isEmpty { Text(error).font(.system(size: 12)).foregroundStyle(.red) }
                    }
                }
                Text("Pas encore de diagnostic ?").font(.system(size: 12)).foregroundStyle(Brand.muted)
                Link("Commencer sur le site →", destination: URL(string: "https://app.eperformance.pro/diagnostic")!).font(.system(size: 13, weight: .semibold)).foregroundStyle(Brand.ink)
            }.padding(24).frame(maxWidth: 560)
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var session: SessionStore
    var body: some View {
        TabView {
            DashboardView().tabItem { Label("Aujourd’hui", systemImage: "sun.max") }
            DiagnosticView().tabItem { Label("Diagnostic", systemImage: "chart.bar") }
            ContactView().tabItem { Label("Contact", systemImage: "bubble.left.and.bubble.right") }
            BookingView().tabItem { Label("Rendez-vous", systemImage: "calendar") }
            ProfileView().tabItem { Label("Profil", systemImage: "person") }
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject var session: SessionStore
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack { BrandMark(); Spacer(); Text(session.role == "admin" ? "ADMIN" : "CLIENT").font(.system(size: 9, weight: .bold)).tracking(1.4).padding(.horizontal, 10).padding(.vertical, 6).overlay(Capsule().stroke(Brand.line)) }
                    SectionTitle(eyebrow: "Votre espace", title: "Bonjour \(session.name.isEmpty ? "à vous" : session.name).")
                    Text("Votre diagnostic, vos échanges et vos prochaines actions, dans une app native.").font(.system(size: 14)).foregroundStyle(Brand.muted)
                    Card { VStack(alignment: .leading, spacing: 12) { Text("VOTRE PROCHAINE ÉTAPE").font(.system(size: 10, weight: .bold)).tracking(1.4).foregroundStyle(Brand.gold); Text("Clarifier votre acquisition.").font(.system(size: 22, weight: .semibold, design: .serif)); Text("Répondez au diagnostic, puis choisissez un appel de 20 minutes.").font(.system(size: 13)).foregroundStyle(Brand.muted) } }
                    HStack(spacing: 12) {
                        StatCard(value: "30", label: "jours de plan")
                        StatCard(value: "1", label: "priorité")
                    }
                    Card { VStack(alignment: .leading, spacing: 10) { Text("Accès rapides").font(.system(size: 13, weight: .semibold)); Link("Diagnostic gratuit →", destination: URL(string: "https://app.eperformance.pro/diagnostic")!); Link("Réserver un appel →", destination: URL(string: "https://cal.eperformance.pro/kstephane")!); Link("Site ePerformance →", destination: URL(string: "https://eperformance.pro")!) }.font(.system(size: 13)) }
                }.padding(20)
            }.background(Brand.cream.ignoresSafeArea()).navigationTitle("").navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct StatCard: View {
    let value: String; let label: String
    var body: some View { VStack(alignment: .leading, spacing: 4) { Text(value).font(.system(size: 30, weight: .semibold, design: .serif)); Text(label.uppercased()).font(.system(size: 9, weight: .bold)).tracking(1.2).foregroundStyle(Brand.muted) }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(Brand.paper).overlay(RoundedRectangle(cornerRadius: 16).stroke(Brand.line)).clipShape(RoundedRectangle(cornerRadius: 16)) }
}

struct DiagnosticView: View {
    @EnvironmentObject var session: SessionStore
    @State private var priority = "leads"
    @State private var blocker = "prospects"
    @State private var goal = ""
    @State private var busy = false
    @State private var message = ""
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionTitle(eyebrow: "Diagnostic", title: "Votre réalité.")
                    Text("Un diagnostic natif, sans formulaire interminable.").font(.system(size: 13)).foregroundStyle(Brand.muted)
                    Card {
                        VStack(alignment: .leading, spacing: 14) {
                            FieldLabel(text: "Priorité")
                            Picker("Priorité", selection: $priority) { Text("Plus de contacts").tag("leads"); Text("Plus de ventes").tag("sales"); Text("Visibilité").tag("visibility"); Text("Recruter").tag("recruit") }.pickerStyle(.menu)
                            FieldLabel(text: "Blocage")
                            Picker("Blocage", selection: $blocker) { Text("Pas assez de prospects").tag("prospects"); Text("Conversion faible").tag("conversion"); Text("Pas de suivi").tag("suivi"); Text("Budget publicitaire").tag("budget"); Text("Notoriété").tag("notoriete") }.pickerStyle(.menu)
                            FieldLabel(text: "Objectif à 90 jours")
                            TextField("Ex : 20 leads qualifiés par mois", text: $goal, axis: .vertical).textFieldStyle(.roundedBorder).lineLimit(2...4)
                            PrimaryButton(title: busy ? "Envoi…" : "Envoyer mon diagnostic", disabled: busy) {
                                Task {
                                    busy = true; message = ""
                                    do {
                                        try await APIClient.shared.submitDiagnostic(["name": session.name, "email": session.email, "businessType": "pme", "priority": priority, "stage": "croissance", "blocker": blocker, "measurementLevel": "partial", "goal": goal, "adsActive": false, "website": true, "channels": []])
                                        message = "Diagnostic enregistré. Votre rapport sera publié dans votre espace."
                                    } catch let err { message = err.localizedDescription }
                                    busy = false
                                }
                            }
                            if !message.isEmpty { Text(message).font(.system(size: 12)).foregroundStyle(message.contains("enregistré") ? Brand.muted : .red) }
                        }
                    }
                }.padding(20)
            }.background(Brand.cream.ignoresSafeArea())
        }
    }
}

struct ContactView: View {
    @EnvironmentObject var session: SessionStore
    @State private var company = ""
    @State private var country = ""
    @State private var message = ""
    @State private var priority = "leads"
    @State private var busy = false
    @State private var status = ""
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionTitle(eyebrow: "Contact", title: "Parlons-en.")
                    Text("Votre message arrive directement dans l’admin ePerformance.").font(.system(size: 13)).foregroundStyle(Brand.muted)
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            FieldLabel(text: "Entreprise")
                            TextField("EGUIFEC, ...", text: $company).textFieldStyle(.roundedBorder)
                            FieldLabel(text: "Pays")
                            TextField("Côte d’Ivoire, Guinée, France…", text: $country).textFieldStyle(.roundedBorder)
                            FieldLabel(text: "Priorité")
                            Picker("Priorité", selection: $priority) { Text("Plus de contacts").tag("leads"); Text("Plus de ventes").tag("sales"); Text("Visibilité").tag("visibility"); Text("Autre").tag("other") }.pickerStyle(.menu)
                            FieldLabel(text: "Message")
                            TextField("Votre situation…", text: $message, axis: .vertical).textFieldStyle(.roundedBorder).lineLimit(3...6)
                            PrimaryButton(title: busy ? "Envoi…" : "Envoyer", disabled: busy || message.isEmpty) {
                                Task {
                                    busy = true; status = ""
                                    do {
                                        try await APIClient.shared.submitContact(["name": session.name, "company": company, "country": country, "email": session.email, "whatsapp": "", "source": "ios", "segment": "pme", "priority": priority, "message": message, "consent": true])
                                        status = "Message reçu. Je reviens vers vous sous 24 h."
                                        message = ""
                                    } catch let err { status = err.localizedDescription }
                                    busy = false
                                }
                            }
                            if !status.isEmpty { Text(status).font(.system(size: 12)).foregroundStyle(status.contains("reçu") ? Brand.muted : .red) }
                        }
                    }
                }.padding(20)
            }.background(Brand.cream.ignoresSafeArea())
        }
    }
}

struct BookingView: View {
    @EnvironmentObject var session: SessionStore
    @State private var date = Date().addingTimeInterval(86400)
    @State private var note = ""
    @State private var busy = false
    @State private var status = ""
    private let iso = ISO8601DateFormatter()
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionTitle(eyebrow: "Rendez-vous", title: "20 minutes.")
                    Text("Proposez un créneau. Je confirme sous 24 heures ouvrées.").font(.system(size: 13)).foregroundStyle(Brand.muted)
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            DatePicker("Créneau souhaité", selection: $date, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                            FieldLabel(text: "Contexte")
                            TextField("Votre besoin…", text: $note, axis: .vertical).textFieldStyle(.roundedBorder).lineLimit(2...5)
                            PrimaryButton(title: busy ? "Envoi…" : "Demander ce créneau", disabled: busy) {
                                Task {
                                    busy = true; status = ""
                                    do {
                                        try await APIClient.shared.requestAppointment(["name": session.name, "email": session.email, "whatsapp": "", "preferredAt": iso.string(from: date), "message": note])
                                        status = "Demande enregistrée. Je confirme le créneau."
                                    } catch let err { status = err.localizedDescription }
                                    busy = false
                                }
                            }
                            if !status.isEmpty { Text(status).font(.system(size: 12)).foregroundStyle(status.contains("enregistrée") ? Brand.muted : .red) }
                        }
                    }
                    Link("Ouvrir Cal.com →", destination: URL(string: "https://cal.eperformance.pro/kstephane")!).font(.system(size: 13, weight: .semibold))
                }.padding(20)
            }.background(Brand.cream.ignoresSafeArea())
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var session: SessionStore
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                SectionTitle(eyebrow: "Compte", title: "Profil.")
                Card { VStack(alignment: .leading, spacing: 10) { Text(session.name.isEmpty ? "Client ePerformance" : session.name).font(.system(size: 18, weight: .semibold, design: .serif)); Text(session.email).font(.system(size: 13)).foregroundStyle(Brand.muted); Text(session.role == "admin" ? "Administrateur" : "Client").font(.system(size: 11)).foregroundStyle(Brand.gold) } }
                Link("Ouvrir le site ePerformance →", destination: URL(string: "https://eperformance.pro")!)
                PrimaryButton(title: "Se déconnecter") { session.signOut() }
                Spacer()
            }.padding(20).background(Brand.cream.ignoresSafeArea())
        }
    }
}
