import SwiftUI

struct LeadDetailView: View {
    let lead: Lead
    @Environment(\.dismiss) var dismiss
    @State private var status = "new"
    @State private var notes = ""
    @State private var busy = false
    @State private var error = ""
    @State private var converted = false
    var body: some View {
        Form {
            Section("Contact") {
                LabeledContent("Nom", value: lead.name)
                LabeledContent("Email", value: lead.email)
                if let c = lead.company { LabeledContent("Entreprise", value: c) }
                LabeledContent("Source", value: lead.source)
                LabeledContent("Segment", value: lead.segment.uppercased())
                if let m = lead.message { Text(m).font(.system(size: 13)) }
            }
            Section("Qualification") {
                Picker("Statut", selection: $status) {
                    Text("Nouveau").tag("new"); Text("Qualifié").tag("qualified")
                    Text("Diagnostic envoyé").tag("diagnostic_sent"); Text("Appel planifié").tag("call")
                    Text("Proposition").tag("proposal"); Text("Client").tag("client"); Text("Perdu").tag("lost")
                }
                TextField("Notes internes", text: $notes, axis: .vertical).lineLimit(3...6)
                Button(busy ? "Enregistrement…" : "Enregistrer le statut") { Task { await saveStatus() } }.disabled(busy)
            }
            Section("Diagnostic") {
                if converted { Label("Diagnostic créé", systemImage: "checkmark.circle.fill").foregroundStyle(Brand.gold) }
                else { Button("Créer le diagnostic prérempli") { Task { await convert() } }.disabled(busy) }
            }
            if !error.isEmpty { Section { Text(error).foregroundStyle(Brand.danger) } }
        }
        .navigationTitle(lead.name)
        .onAppear { status = lead.status }
    }
    func saveStatus() async {
        busy = true; error = ""
        do { try await AdminAPI.shared.performAction(["action":"lead_status","id":lead.id,"status":status,"notes":notes]); dismiss() }
        catch let e { error = e.localizedDescription }
        busy = false
    }
    func convert() async {
        busy = true; error = ""
        do { try await AdminAPI.shared.performAction(["action":"convert_lead","id":lead.id]); converted = true }
        catch let e { error = e.localizedDescription }
        busy = false
    }
}

struct AppointmentDetailView: View {
    let appointment: Appointment
    @Environment(\.dismiss) var dismiss
    @State private var status = "requested"
    @State private var busy = false
    @State private var error = ""
    var body: some View {
        Form {
            Section("Demande") {
                LabeledContent("Nom", value: appointment.name)
                LabeledContent("Email", value: appointment.email)
                if let w = appointment.whatsapp { LabeledContent("WhatsApp", value: w) }
                LabeledContent("Créneau", value: appointment.preferredAt ?? "À définir")
                if let m = appointment.message { Text(m).font(.system(size: 13)) }
            }
            Section("Statut") {
                Picker("Statut", selection: $status) {
                    Text("Demandé").tag("requested"); Text("Confirmé").tag("confirmed")
                    Text("Terminé").tag("done"); Text("Annulé").tag("cancelled")
                }
                Button(busy ? "Enregistrement…" : "Mettre à jour") { Task { await save() } }.disabled(busy)
            }
            if !error.isEmpty { Section { Text(error).foregroundStyle(Brand.danger) } }
        }.navigationTitle(appointment.name).onAppear { status = appointment.status }
    }
    func save() async {
        busy = true; error = ""
        do { try await AdminAPI.shared.performAction(["action":"appointment_status","id":appointment.id,"status":status]); dismiss() }
        catch let e { error = e.localizedDescription }
        busy = false
    }
}

struct DiagnosticDetailView: View {
    let diagnostic: Diagnostic
    @Environment(\.dismiss) var dismiss
    @State private var title = "Rapport acquisition ePerformance"
    @State private var summary = ""
    @State private var score = "68"
    @State private var busy = false
    @State private var error = ""
    @State private var published = false
    var body: some View {
        Form {
            Section("Diagnostic") {
                LabeledContent("Nom", value: diagnostic.name)
                LabeledContent("Email", value: diagnostic.email)
                LabeledContent("Parcours", value: diagnostic.businessType.uppercased())
                LabeledContent("Priorité", value: diagnostic.priority ?? "—")
                LabeledContent("Statut", value: diagnostic.status)
            }
            Section("Publier le rapport") {
                TextField("Titre", text: $title)
                TextField("Résumé", text: $summary, axis: .vertical).lineLimit(3...6)
                TextField("Score /100", text: $score).keyboardType(.numberPad)
                Button(busy ? "Publication…" : "Publier le rapport") { Task { await publish() } }.disabled(busy || summary.isEmpty)
                if published { Label("Rapport publié", systemImage: "checkmark.circle.fill").foregroundStyle(Brand.gold) }
            }
            if !error.isEmpty { Section { Text(error).foregroundStyle(Brand.danger) } }
        }.navigationTitle("Diagnostic")
        .onAppear { summary = "Votre acquisition dépend encore trop du hasard. Votre priorité : \(diagnostic.priority ?? "structurer le suivi")." }
    }
    func publish() async {
        busy = true; error = ""
        do {
            try await AdminAPI.shared.performAction(["action":"publish_report","diagnosticId":diagnostic.id,"title":title,"summary":summary,"score":Int(score) ?? 0,"signals":["Le suivi des prospects","Le budget publicitaire","La mesure des résultats"]])
            published = true
        } catch let e { error = e.localizedDescription }
        busy = false
    }
}
