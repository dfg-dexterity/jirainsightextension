import AppKit
import SwiftUI

struct RootView: View {
    @ObservedObject var tracker: FrontWindowTracker
    @StateObject private var model = TicketViewModel()
    @State private var showSettings = false

    var body: some View {
        Group {
            if showSettings || model.phase == .needsSetup {
                SettingsView {
                    showSettings = false
                    Task { await model.start(tracker: tracker) }
                }
            } else {
                content
            }
        }
        .frame(width: 400, alignment: .top)
        .onReceive(NotificationCenter.default.publisher(for: .jqtPopoverOpened)) { _ in
            Task { await model.start(tracker: tracker) }
        }
        .task { await model.start(tracker: tracker) }
    }

    @ViewBuilder private var content: some View {
        switch model.phase {
        case .needsSetup:
            EmptyView()
        case .loading:
            ProgressView("Carregando…")
                .frame(maxWidth: .infinity, minHeight: 220)
        case .form, .creating:
            TicketFormView(model: model, tracker: tracker) { showSettings = true }
        case .success(let key, let url, let worklogNote):
            SuccessView(model: model, key: key, url: url, worklogNote: worklogNote)
        }
    }
}

struct TicketFormView: View {
    @ObservedObject var model: TicketViewModel
    @ObservedObject var tracker: FrontWindowTracker
    var onSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Jira Quick Ticket", systemImage: "plus.square.fill")
                    .font(.headline)
                Spacer()
                Button(action: onSettings) {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .help("Configurações")
                Button(action: { NSApp.terminate(nil) }) {
                    Image(systemName: "power")
                }
                .buttonStyle(.plain)
                .help("Sair do Jira Quick Ticket")
            }

            if !tracker.accessibilityGranted {
                Text("Sem permissão de Acessibilidade: o título da janela não pôde ser lido. Libere em Ajustes do Sistema → Privacidade e Segurança → Acessibilidade.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            TextField("Filtrar projetos por nome ou chave…", text: $model.projectFilter)

            Picker("Projeto", selection: $model.selectedProjectId) {
                ForEach(model.filteredProjects) { project in
                    Text("\(project.name) (\(project.key))").tag(project.id)
                }
            }
            .onChange(of: model.selectedProjectId) { _ in
                Task { await model.loadTypes() }
            }

            Picker("Tipo", selection: $model.selectedTypeId) {
                ForEach(model.issueTypes) { type in
                    Text(type.name).tag(type.id)
                }
            }

            Text("Resumo")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("Resumo do ticket", text: $model.summary)

            Text("Descrição")
                .font(.caption)
                .foregroundColor(.secondary)
            TextEditor(text: $model.descriptionText)
                .font(.body)
                .frame(height: 110)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.35)))

            Text("Apontar horas (opcional)")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("ex.: 1h 30m • 45m • 2 • 1:30", text: $model.timeSpent)

            if let error = model.errorMessage {
                Text(error)
                    .font(.callout)
                    .foregroundColor(.red)
                    .textSelection(.enabled)
            }

            HStack {
                Button("↻ Projetos") {
                    Task { await model.refreshProjects() }
                }
                .disabled(model.phase == .creating)
                .help("Recarregar a lista de projetos do Jira")
                Spacer()
                Button(model.phase == .creating ? "Criando…" : "Criar ticket") {
                    Task { await model.create() }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(model.phase == .creating)
            }
        }
        .padding(14)
        .textFieldStyle(.roundedBorder)
    }
}

struct SuccessView: View {
    @ObservedObject var model: TicketViewModel
    let key: String
    let url: URL?
    let worklogNote: String
    @State private var copied = false

    var body: some View {
        VStack(spacing: 10) {
            Text("Ticket criado!")
                .font(.headline)
                .foregroundColor(.green)
            Text(key)
                .font(.system(size: 30, weight: .bold))
                .textSelection(.enabled)
            Text(model.lastSummary)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            if !worklogNote.isEmpty {
                Text(worklogNote)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            HStack {
                Button(copied ? "Copiado ✓" : "Copiar chave") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(key, forType: .string)
                    copied = true
                }
                if let url {
                    Button("Abrir no Jira") { NSWorkspace.shared.open(url) }
                }
                Button("Criar outro") {
                    model.timeSpent = ""
                    model.phase = .form
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}

struct SettingsView: View {
    var onDone: () -> Void

    @State private var baseUrl = UserDefaults.standard.string(forKey: "jiraBaseUrl") ?? JiraSettings.defaultBaseUrl
    @State private var email = UserDefaults.standard.string(forKey: "jiraEmail") ?? ""
    @State private var token = Keychain.load(account: "jiraApiToken") ?? ""
    @State private var status: String?
    @State private var statusIsError = false
    @State private var testing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Jira Quick Ticket — Configurações")
                .font(.headline)
            Text("Credenciais usadas para falar com a API do Jira Cloud. O token fica no Keychain do macOS e é enviado somente para o seu site Jira.")
                .font(.callout)
                .foregroundColor(.secondary)

            Text("URL do Jira")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("https://suaempresa.atlassian.net", text: $baseUrl)

            Text("E-mail (conta Atlassian)")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("voce@empresa.com", text: $email)

            Text("API token")
                .font(.caption)
                .foregroundColor(.secondary)
            SecureField("cole o token aqui", text: $token)
            Link(
                "Gerar um API token (id.atlassian.com → Security → API tokens)",
                destination: URL(string: "https://id.atlassian.com/manage-profile/security/api-tokens")!
            )
            .font(.callout)

            if let status {
                Text(status)
                    .font(.callout)
                    .foregroundColor(statusIsError ? .red : .green)
                    .textSelection(.enabled)
            }

            HStack {
                Button(testing ? "Testando…" : "Testar conexão") {
                    Task { await test() }
                }
                .disabled(testing)
                Spacer()
                Button("Salvar") { save() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(14)
        .textFieldStyle(.roundedBorder)
    }

    private func currentSettings() -> JiraSettings {
        JiraSettings(
            baseUrl: JiraSettings.normalizeBaseUrl(baseUrl),
            email: email.trimmingCharacters(in: .whitespaces),
            token: token.trimmingCharacters(in: .whitespaces)
        )
    }

    @MainActor
    private func test() async {
        let settings = currentSettings()
        guard !settings.email.isEmpty, !settings.token.isEmpty else {
            status = "Preencha e-mail e API token."
            statusIsError = true
            return
        }
        testing = true
        defer { testing = false }
        do {
            let name = try await JiraClient(settings: settings).myself()
            status = "Conectado como \(name)."
            statusIsError = false
        } catch {
            status = error.localizedDescription
            statusIsError = true
        }
    }

    private func save() {
        let settings = currentSettings()
        guard !settings.email.isEmpty, !settings.token.isEmpty else {
            status = "Preencha e-mail e API token."
            statusIsError = true
            return
        }
        settings.save()
        onDone()
    }
}
