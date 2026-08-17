import SwiftUI

@MainActor
final class TicketViewModel: ObservableObject {
    enum Phase: Equatable {
        case needsSetup
        case loading
        case form
        case creating
        case success(key: String, url: URL?, worklogNote: String)
    }

    @Published var phase: Phase = .loading
    @Published var projects: [JiraProject] = []
    @Published var issueTypes: [JiraIssueType] = []
    @Published var projectFilter = ""
    @Published var selectedProjectId = ""
    @Published var selectedTypeId = ""
    @Published var summary = ""
    @Published var descriptionText = ""
    @Published var timeSpent = ""
    @Published var errorMessage: String?
    @Published var lastSummary = ""

    private var client: JiraClient?
    private let defaults = UserDefaults.standard
    private let cacheTTL: TimeInterval = 24 * 60 * 60

    private struct ProjectsCache: Codable {
        let fetchedAt: Date
        let projects: [JiraProject]
    }

    var filteredProjects: [JiraProject] {
        let filter = projectFilter.trimmingCharacters(in: .whitespaces).lowercased()
        guard !filter.isEmpty else { return projects }
        return projects.filter {
            $0.name.lowercased().contains(filter) || $0.key.lowercased().contains(filter)
        }
    }

    /// Chamado a cada abertura do popover: revalida credenciais, repõe a
    /// captura da janela ativa e garante a lista de projetos.
    func start(tracker: FrontWindowTracker) async {
        errorMessage = nil
        guard let settings = JiraSettings.load() else {
            phase = .needsSetup
            return
        }
        client = JiraClient(settings: settings)
        populate(from: tracker)
        if case .success = phase { phase = .form }
        if projects.isEmpty {
            phase = .loading
            do {
                try await loadProjects(forceRefresh: false)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        if phase == .loading { phase = .form }
    }

    func populate(from tracker: FrontWindowTracker) {
        summary = tracker.windowTitle.isEmpty ? tracker.appName : tracker.windowTitle
        var lines: [String] = []
        if !tracker.appName.isEmpty { lines.append("Aplicativo: \(tracker.appName)") }
        if !tracker.windowTitle.isEmpty { lines.append("Janela: \(tracker.windowTitle)") }
        if !tracker.selectedText.isEmpty {
            lines.append("")
            lines.append("Texto selecionado:")
            lines.append(tracker.selectedText)
        }
        descriptionText = lines.joined(separator: "\n")
        timeSpent = ""
    }

    func refreshProjects() async {
        errorMessage = nil
        do {
            try await loadProjects(forceRefresh: true)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadProjects(forceRefresh: Bool) async throws {
        if !forceRefresh,
           let data = defaults.data(forKey: "projectsCache"),
           let cache = try? JSONDecoder().decode(ProjectsCache.self, from: data),
           Date().timeIntervalSince(cache.fetchedAt) < cacheTTL,
           !cache.projects.isEmpty {
            projects = cache.projects
        } else if let client {
            projects = try await client.fetchProjects()
            let cache = ProjectsCache(fetchedAt: Date(), projects: projects)
            if let data = try? JSONEncoder().encode(cache) {
                defaults.set(data, forKey: "projectsCache")
            }
        }
        applyDefaultSelection()
        await loadTypes()
    }

    private func applyDefaultSelection() {
        if projects.contains(where: { $0.id == selectedProjectId }) { return }
        if let last = defaults.string(forKey: "lastProjectId"),
           projects.contains(where: { $0.id == last }) {
            selectedProjectId = last
        } else {
            selectedProjectId = projects.first?.id ?? ""
        }
    }

    func loadTypes() async {
        guard let projectIndex = projects.firstIndex(where: { $0.id == selectedProjectId }) else {
            issueTypes = []
            selectedTypeId = ""
            return
        }
        var types = projects[projectIndex].issueTypes
        if types.isEmpty, let client {
            types = (try? await client.fetchIssueTypes(projectId: projects[projectIndex].id)) ?? []
            projects[projectIndex].issueTypes = types
        }
        issueTypes = types
        let lastByProject = defaults.dictionary(forKey: "lastTypeByProject") as? [String: String]
        if let last = lastByProject?[selectedProjectId], types.contains(where: { $0.id == last }) {
            selectedTypeId = last
        } else if !types.contains(where: { $0.id == selectedTypeId }) {
            selectedTypeId = types.first?.id ?? ""
        }
    }

    func create() async {
        errorMessage = nil
        guard let client else { return }
        guard !selectedProjectId.isEmpty else {
            errorMessage = "Escolha um projeto."
            return
        }
        guard !selectedTypeId.isEmpty else {
            errorMessage = "Escolha o tipo de ticket."
            return
        }
        let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSummary.isEmpty else {
            errorMessage = "Informe o resumo do ticket."
            return
        }

        phase = .creating
        do {
            let key = try await client.createIssue(
                projectId: selectedProjectId,
                issueTypeId: selectedTypeId,
                summary: trimmedSummary,
                description: descriptionText
            )
            defaults.set(selectedProjectId, forKey: "lastProjectId")
            var lastByProject = (defaults.dictionary(forKey: "lastTypeByProject") as? [String: String]) ?? [:]
            lastByProject[selectedProjectId] = selectedTypeId
            defaults.set(lastByProject, forKey: "lastTypeByProject")

            var worklogNote = ""
            if let normalized = JiraClient.normalizeTimeSpent(timeSpent) {
                do {
                    try await client.addWorklog(issueKey: key, timeSpent: normalized)
                    worklogNote = "⏱ \(normalized) apontado no ticket"
                } catch {
                    worklogNote = "⚠ Ticket criado, mas o apontamento falhou: \(error.localizedDescription)"
                }
            }
            lastSummary = trimmedSummary
            let url = URL(string: "\(client.settings.baseUrl)/browse/\(key)")
            phase = .success(key: key, url: url, worklogNote: worklogNote)
        } catch {
            errorMessage = error.localizedDescription
            phase = .form
        }
    }
}
