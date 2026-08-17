import Foundation
import Security

// MARK: - Configurações (URL/e-mail em UserDefaults; token no Keychain)

struct JiraSettings {
    var baseUrl: String
    var email: String
    var token: String

    static let defaultBaseUrl = "https://dexterityit.atlassian.net"

    static func normalizeBaseUrl(_ raw: String) -> String {
        var url = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if url.isEmpty { return defaultBaseUrl }
        if !url.lowercased().hasPrefix("http://") && !url.lowercased().hasPrefix("https://") {
            url = "https://" + url
        }
        while url.hasSuffix("/") { url.removeLast() }
        return url
    }

    static func load() -> JiraSettings? {
        let defaults = UserDefaults.standard
        guard let email = defaults.string(forKey: "jiraEmail"), !email.isEmpty,
              let token = Keychain.load(account: "jiraApiToken"), !token.isEmpty
        else { return nil }
        let baseUrl = normalizeBaseUrl(defaults.string(forKey: "jiraBaseUrl") ?? "")
        return JiraSettings(baseUrl: baseUrl, email: email, token: token)
    }

    func save() {
        let defaults = UserDefaults.standard
        defaults.set(Self.normalizeBaseUrl(baseUrl), forKey: "jiraBaseUrl")
        defaults.set(email.trimmingCharacters(in: .whitespaces), forKey: "jiraEmail")
        Keychain.save(token.trimmingCharacters(in: .whitespaces), account: "jiraApiToken")
    }
}

enum Keychain {
    private static let service = "br.com.dexterity.jiraquickticket"

    static func save(_ value: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = Data(value.utf8)
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func load(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - Modelos

struct JiraIssueType: Codable, Identifiable, Hashable {
    let id: String
    let name: String
}

struct JiraProject: Codable, Identifiable, Hashable {
    let id: String
    let key: String
    let name: String
    var issueTypes: [JiraIssueType]
}

struct JiraError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

// MARK: - Cliente da API REST do Jira Cloud (v3)

struct JiraClient {
    let settings: JiraSettings

    private func request(_ path: String, method: String = "GET", body: [String: Any]? = nil) async throws -> Data {
        guard let url = URL(string: settings.baseUrl + path) else {
            throw JiraError(message: "URL do Jira inválida: \(settings.baseUrl)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        let credentials = Data("\(settings.email):\(settings.token)".utf8).base64EncodedString()
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw JiraError(message: "Não foi possível conectar a \(settings.baseUrl). Verifique a URL e sua rede.")
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200...299).contains(status) else {
            throw JiraError(message: Self.readableError(status: status, data: data))
        }
        return data
    }

    private static func readableError(status: Int, data: Data) -> String {
        let fallback: String
        switch status {
        case 400: fallback = "Requisição inválida — o projeto pode exigir campos obrigatórios extras."
        case 401: fallback = "Credenciais inválidas. Confira o e-mail e o API token nas configurações."
        case 403: fallback = "Sem permissão para esta operação no Jira."
        case 404: fallback = "Recurso não encontrado — confira a URL do Jira nas configurações."
        default: fallback = "Erro \(status) na API do Jira."
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return fallback }
        var messages: [String] = []
        if let list = json["errorMessages"] as? [String] { messages.append(contentsOf: list) }
        if let fields = json["errors"] as? [String: String] {
            messages.append(contentsOf: fields.map { "\($0.key): \($0.value)" })
        }
        return messages.isEmpty ? fallback : messages.joined(separator: " • ")
    }

    // MARK: Chamadas

    func myself() async throws -> String {
        let data = try await request("/rest/api/3/myself")
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["displayName"] as? String ?? settings.email
    }

    /// Projetos onde o usuário pode criar tickets, com os tipos disponíveis (sem subtarefas).
    func fetchProjects() async throws -> [JiraProject] {
        struct RawType: Decodable {
            let id: String
            let name: String
            let subtask: Bool?
        }
        struct RawProject: Decodable {
            let id: String
            let key: String
            let name: String
            let issueTypes: [RawType]?
        }
        struct Page: Decodable {
            let isLast: Bool?
            let values: [RawProject]?
        }

        var projects: [JiraProject] = []
        var startAt = 0
        while true {
            let path = "/rest/api/3/project/search?action=create&expand=issueTypes&orderBy=name&maxResults=50&startAt=\(startAt)"
            let data = try await request(path)
            let page = try JSONDecoder().decode(Page.self, from: data)
            let values = page.values ?? []
            projects.append(contentsOf: values.map { raw in
                JiraProject(
                    id: raw.id,
                    key: raw.key,
                    name: raw.name,
                    issueTypes: (raw.issueTypes ?? [])
                        .filter { $0.subtask != true }
                        .map { JiraIssueType(id: $0.id, name: $0.name) }
                )
            })
            if page.isLast ?? true || values.isEmpty { break }
            startAt = projects.count
        }
        return projects
    }

    /// Fallback quando o projeto não veio com issueTypes no expand.
    func fetchIssueTypes(projectId: String) async throws -> [JiraIssueType] {
        struct RawType: Decodable {
            let id: String
            let name: String
            let subtask: Bool?
        }
        struct Page: Decodable {
            let issueTypes: [RawType]?
            let values: [RawType]?
        }
        let data = try await request("/rest/api/3/issue/createmeta/\(projectId)/issuetypes?maxResults=200")
        let page = try JSONDecoder().decode(Page.self, from: data)
        return (page.issueTypes ?? page.values ?? [])
            .filter { $0.subtask != true }
            .map { JiraIssueType(id: $0.id, name: $0.name) }
    }

    func createIssue(projectId: String, issueTypeId: String, summary: String, description: String) async throws -> String {
        var fields: [String: Any] = [
            "project": ["id": projectId],
            "issuetype": ["id": issueTypeId],
            "summary": summary,
        ]
        let text = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            fields["description"] = Self.textToAdf(text)
        }
        let data = try await request("/rest/api/3/issue", method: "POST", body: ["fields": fields])
        struct Created: Decodable { let key: String }
        return try JSONDecoder().decode(Created.self, from: data).key
    }

    func addWorklog(issueKey: String, timeSpent: String) async throws {
        _ = try await request(
            "/rest/api/3/issue/\(issueKey)/worklog",
            method: "POST",
            body: ["timeSpent": timeSpent]
        )
    }

    // MARK: Utilitários

    /// Texto simples → Atlassian Document Format: linhas em branco separam
    /// parágrafos, quebras simples viram hardBreak.
    static func textToAdf(_ text: String) -> [String: Any] {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        let blocks = normalized
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\n")) }
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let content: [[String: Any]] = blocks.map { block in
            var inline: [[String: Any]] = []
            for (index, line) in block.components(separatedBy: "\n").enumerated() {
                if index > 0 { inline.append(["type": "hardBreak"]) }
                if !line.isEmpty { inline.append(["type": "text", "text": line]) }
            }
            return ["type": "paragraph", "content": inline]
        }
        return ["type": "doc", "version": 1, "content": content]
    }

    /// "2" → "2h", "1,5"/"1.5" → "1h 30m", "1:30" → "1h 30m"; formatos do
    /// Jira ("1h 30m", "45m", "1d") passam direto. Vazio → nil.
    static func normalizeTimeSpent(_ raw: String) -> String? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if text.isEmpty { return nil }

        func format(hours: Int, minutes: Int) -> String? {
            let totalHours = hours + minutes / 60
            let rest = minutes % 60
            var parts: [String] = []
            if totalHours > 0 { parts.append("\(totalHours)h") }
            if rest > 0 { parts.append("\(rest)m") }
            return parts.isEmpty ? nil : parts.joined(separator: " ")
        }

        // "1:30" → 1h 30m
        if text.contains(":") {
            let parts = text.split(separator: ":")
            if parts.count == 2,
               let hours = Int(parts[0]),
               let minutes = Int(parts[1]),
               parts[1].count <= 2 {
                return format(hours: hours, minutes: minutes)
            }
            return text
        }

        // "2" → 2h; "1,5"/"1.5" → 1h 30m
        let decimalText = text.replacingOccurrences(of: ",", with: ".")
        if decimalText.allSatisfy({ "0123456789.".contains($0) }), let value = Double(decimalText) {
            let hours = Int(value)
            let minutes = Int(((value - Double(hours)) * 60).rounded())
            return format(hours: hours, minutes: minutes)
        }

        return text
    }
}
