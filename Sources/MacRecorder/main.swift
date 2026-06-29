import AppKit

// MacRecorder — a standalone menu-bar app that records the screen with system
// audio (no mic), triggered by ⌘⇧5, saving straight to ~/Downloads.
let app = NSApplication.shared
app.setActivationPolicy(.accessory) // menu-bar only, no Dock icon
let delegate = AppDelegate()
app.delegate = delegate
app.run()
