import AppKit
import StatusItemKit

// MacRecorder — a standalone menu-bar app that records the screen with system
// audio (no mic), triggered by ⌘⇧5, saving straight to ~/Downloads.
// Handle `--login on|off|status` and exit before any UI exists. Start at Login is
// SMAppService.mainApp, which can only register the calling process's own bundle,
// so this is the only way an installer or script can turn it on.
LoginCLI.runIfRequested()

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // menu-bar only, no Dock icon
let delegate = AppDelegate()
app.delegate = delegate
app.run()
