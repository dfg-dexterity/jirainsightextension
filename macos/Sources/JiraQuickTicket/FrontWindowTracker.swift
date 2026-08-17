import AppKit
import ApplicationServices

/// Observa qual aplicativo está em primeiro plano e captura, sob demanda,
/// o nome do app, o título da janela ativa e o texto selecionado (via
/// API de Acessibilidade — requer permissão em Privacidade > Acessibilidade).
final class FrontWindowTracker: ObservableObject {
    @Published var appName = ""
    @Published var windowTitle = ""
    @Published var selectedText = ""
    @Published var accessibilityGranted = true

    private var lastOtherApp: NSRunningApplication?

    func start() {
        if let front = NSWorkspace.shared.frontmostApplication, !isSelf(front) {
            lastOtherApp = front
        }
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self,
                  let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  !self.isSelf(app)
            else { return }
            self.lastOtherApp = app
        }
    }

    func captureNow() {
        let front = NSWorkspace.shared.frontmostApplication
        let target = (front != nil && !isSelf(front!)) ? front : lastOtherApp

        appName = target?.localizedName ?? ""
        windowTitle = ""
        selectedText = ""

        guard let pid = target?.processIdentifier else { return }

        // Na primeira vez o sistema mostra o pedido de permissão de Acessibilidade.
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        accessibilityGranted = AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
        guard accessibilityGranted else { return }

        let axApp = AXUIElementCreateApplication(pid)

        var windowRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &windowRef) == .success,
           let windowRef {
            let window = windowRef as! AXUIElement
            var titleRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef) == .success {
                windowTitle = (titleRef as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        var focusedRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(axApp, kAXFocusedUIElementAttribute as CFString, &focusedRef) == .success,
           let focusedRef {
            let focused = focusedRef as! AXUIElement
            var selectionRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(focused, kAXSelectedTextAttribute as CFString, &selectionRef) == .success {
                selectedText = (selectionRef as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    }

    private func isSelf(_ app: NSRunningApplication) -> Bool {
        app.processIdentifier == ProcessInfo.processInfo.processIdentifier
    }
}
