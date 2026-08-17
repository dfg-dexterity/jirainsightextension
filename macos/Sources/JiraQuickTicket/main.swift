import AppKit

// App de barra de menus (sem ícone no Dock): ver AppDelegate.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
