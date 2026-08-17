import AppKit
import SwiftUI

extension Notification.Name {
    // Disparada a cada abertura do popover, para a UI recarregar a captura.
    static let jqtPopoverOpened = Notification.Name("jqtPopoverOpened")
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private let tracker = FrontWindowTracker()

    func applicationDidFinishLaunching(_ notification: Notification) {
        tracker.start()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "plus.square.fill",
                accessibilityDescription: "Criar ticket no Jira"
            )
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 400, height: 600)
        popover.contentViewController = NSHostingController(rootView: RootView(tracker: tracker))
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            // Captura ANTES de mostrar o popover, enquanto o app do usuário ainda é o frontal.
            tracker.captureNow()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            NotificationCenter.default.post(name: .jqtPopoverOpened, object: nil)
        }
    }
}
