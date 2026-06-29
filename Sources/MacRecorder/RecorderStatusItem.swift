import AppKit
import StatusItemKit

/// Owns the menu-bar item. Two interaction states:
///   • idle — any click opens the menu (record options, prefs, quit).
///   • recording — a left-click stops immediately (red dot); a right- or
///     control-click still opens the menu (so Quit/Stop stay reachable).
///
/// This is a bespoke status item rather than StatusItemKit's menu-only
/// `StatusItemController` because that two-state click behavior needs direct
/// control of the button action; it still reuses StatusItemKit's `MeterIcon`.
final class RecorderStatusItem: NSObject {
    /// Invoked when the user left-clicks the icon while recording.
    var onStopClick: (() -> Void)?
    /// Populates the menu when it should open.
    var buildMenu: ((NSMenu) -> Void)?

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var recording = false

    override init() {
        super.init()
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(handleClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        render()
    }

    func setRecording(_ on: Bool) {
        guard recording != on else { return }
        recording = on
        render()
    }

    @objc private func handleClick() {
        let event = NSApp.currentEvent
        let isSecondary = event?.type == .rightMouseUp
            || (event?.modifierFlags.contains(.control) ?? false)

        if recording && !isSecondary {
            onStopClick?()
            return
        }
        showMenu()
    }

    /// Transient-menu trick: attach the menu just long enough to pop it, then
    /// detach so left-clicks keep routing to `handleClick`.
    private func showMenu() {
        let menu = NSMenu()
        buildMenu?(menu)
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func render() {
        guard let button = statusItem.button else { return }
        button.imagePosition = .imageOnly
        if recording {
            // Solid red dot — a clear "REC" indicator, kept full-color.
            button.image = MeterIcon.dot(color: .systemRed)
        } else {
            let image = NSImage(systemSymbolName: "record.circle", accessibilityDescription: "MacRecorder")
            image?.isTemplate = true // let the menu bar tint it (light/dark aware)
            button.image = image
        }
    }
}
