import AppKit
import HotkeyKit
import MacRecorderCore
import StatusItemKit

/// Wires the menu-bar item, the global key tap, the region selector, and the
/// ScreenCaptureKit recorder together.
///
/// Recording is a simple state machine:
///   idle ──(⌘⇧5)────────────────▶ recording
///   idle ──(⌘⌥⇧5)──▶ selectingRegion ──(drag)──▶ recording
///   recording ──(shortcut again / Esc / click dot)──▶ idle (file saved)
///
/// ⌘⇧5 is swallowed by the tap so macOS's Screenshot tool never appears. Esc is
/// only swallowed while recording; otherwise it passes through untouched.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private enum State { case idle, selectingRegion, recording }

    private var statusItem: RecorderStatusItem!
    private let model = BindingsModel()
    private let recorder = Recorder()
    private let regionSelector = RegionSelector()
    private var tap: HotkeyTap!
    private var trustTimer: Timer?
    private var state: State = .idle
    private var prefs: PreferencesWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = RecorderStatusItem()
        statusItem.onStopClick = { [weak self] in self?.stopRecording() }
        statusItem.buildMenu = { [weak self] menu in self?.buildMenu(menu) }

        tap = HotkeyTap(
            bindings: tapBindings(),
            onMatch: { [weak self] token in self?.handle(token: token) ?? false }
        )
        model.onChange = { [weak self] _ in self?.tap.setBindings(self?.tapBindings() ?? []) }
        recorder.onUnexpectedStop = { [weak self] _ in self?.resetToIdle() }

        if !tap.isTrusted { tap.requestTrust() }
        startTapIfPossible()
    }

    /// The two rebindable mode shortcuts plus the fixed Esc-to-stop binding.
    private func tapBindings() -> [Binding] { model.bindings + [BindingStore.stopEsc] }

    // MARK: - Tap lifecycle (mirrors KeyLight)

    private func startTapIfPossible() {
        guard tap.isTrusted else { scheduleTrustRecheck(); return }
        if !tap.isRunning { tap.start() }
        trustTimer?.invalidate()
        trustTimer = nil
    }

    private func scheduleTrustRecheck() {
        guard trustTimer == nil else { return }
        trustTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.tap.isTrusted { self.startTapIfPossible() }
        }
    }

    // MARK: - Hotkey handling

    /// Returns true to swallow the key.
    private func handle(token: String) -> Bool {
        switch state {
        case .recording:
            // Any mode shortcut OR Esc stops + saves.
            stopRecording()
            return true
        case .selectingRegion:
            // Swallow the mode shortcuts (keep Screenshot away); let Esc fall
            // through to the overlay window, which cancels the picker.
            return token != BindingStore.stopToken
        case .idle:
            if token == RecordingMode.fullScreen.token { startFullScreen(); return true }
            if token == RecordingMode.region.token { startRegion(); return true }
            return false // bare Esc (stopToken) passes through when idle
        }
    }

    // MARK: - Recording

    private func startFullScreen() {
        guard ensureScreenRecordingPermission() else { return }
        beginRecording(displayID: CGMainDisplayID(), cropRect: nil)
    }

    private func startRegion() {
        guard ensureScreenRecordingPermission() else { return }
        state = .selectingRegion
        regionSelector.begin { [weak self] selection in
            guard let self else { return }
            guard let selection else { self.state = .idle; return }
            self.beginRecording(displayID: selection.displayID, cropRect: selection.rect)
        }
    }

    private func beginRecording(displayID: CGDirectDisplayID, cropRect: CGRect?) {
        state = .recording
        statusItem.setRecording(true)
        let scale = NSScreen.backingScale(for: displayID)
        let url = OutputPath.downloadsURL(for: Date())
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.recorder.start(
                    displayID: displayID, cropRect: cropRect, scale: scale, outputURL: url
                )
            } catch {
                await MainActor.run { self.recordingFailed(error) }
            }
        }
    }

    private func stopRecording() {
        guard state == .recording else { return }
        state = .idle
        statusItem.setRecording(false)
        Task { [weak self] in
            guard let self else { return }
            let url = await self.recorder.stop()
            if let url { await MainActor.run { self.announceSaved(url) } }
        }
    }

    private func recordingFailed(_ error: Error) {
        resetToIdle()
        NSLog("MacRecorder: recording failed — \(error.localizedDescription)")
    }

    private func resetToIdle() {
        state = .idle
        statusItem.setRecording(false)
    }

    private func announceSaved(_ url: URL) {
        // Saved straight to ~/Downloads with no preview; just log the path.
        NSLog("MacRecorder: saved \(url.path)")
    }

    // MARK: - Permissions

    /// True if Screen Recording is granted. If not, prompts and shows guidance,
    /// returning false so the caller aborts this attempt.
    private func ensureScreenRecordingPermission() -> Bool {
        if CGPreflightScreenCaptureAccess() { return true }
        CGRequestScreenCaptureAccess()
        let alert = NSAlert()
        alert.messageText = "Screen Recording permission needed"
        alert.informativeText = "Enable MacRecorder under System Settings ▸ Privacy & "
            + "Security ▸ Screen Recording, then try the shortcut again."
        alert.alertStyle = .informational
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
        return false
    }

    // MARK: - Menu

    private func buildMenu(_ menu: NSMenu) {
        if state == .recording {
            menu.addItem(actionItem("■ Stop Recording", #selector(menuStop)))
            menu.addItem(.separator())
            menu.addItem(actionItem("Quit MacRecorder", #selector(quit), key: "q"))
            return
        }

        for mode in RecordingMode.allCases {
            let shortcut = trigger(for: mode).map { "    " + TriggerFormatter.string($0) } ?? ""
            let selector = (mode == .fullScreen) ? #selector(menuRecordFull) : #selector(menuRecordRegion)
            menu.addItem(actionItem(mode.label + shortcut, selector))
        }

        menu.addItem(.separator())

        if !CGPreflightScreenCaptureAccess() {
            menu.addItem(actionItem("⚠ Grant Screen Recording…", #selector(grantScreenRecording)))
        }
        if !(tap?.isTrusted ?? false) {
            menu.addItem(actionItem("⚠ Grant Accessibility…", #selector(grantAccessibility)))
        }

        menu.addItem(actionItem("Preferences…", #selector(openPrefs), key: ","))

        let login = actionItem("Start at Login", #selector(toggleLogin))
        login.state = LoginItem.isEnabled ? .on : .off
        menu.addItem(login)

        menu.addItem(.separator())
        menu.addItem(actionItem("Quit MacRecorder", #selector(quit), key: "q"))
    }

    private func trigger(for mode: RecordingMode) -> Trigger? {
        model.bindings.first { $0.token == mode.token }?.trigger
    }

    private func actionItem(_ title: String, _ selector: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: key)
        item.target = self
        return item
    }

    // MARK: - Menu selectors

    @objc private func menuStop() { stopRecording() }
    @objc private func menuRecordFull() { if state == .idle { startFullScreen() } }
    @objc private func menuRecordRegion() { if state == .idle { startRegion() } }
    @objc private func grantScreenRecording() { CGRequestScreenCaptureAccess() }
    @objc private func grantAccessibility() { tap.requestTrust(); startTapIfPossible() }

    @objc private func openPrefs() {
        if prefs == nil {
            prefs = PreferencesWindowController(
                model: model,
                // Pause the tap during shortcut capture so the current ⌘⇧5 is
                // recorded rather than starting a real recording; resume after.
                pauseTap: { [weak self] in self?.tap.stop() },
                resumeTap: { [weak self] in self?.startTapIfPossible() }
            )
        }
        prefs?.show()
    }
    @objc private func toggleLogin() { LoginItem.toggle() }
    @objc private func quit() { NSApp.terminate(nil) }
}
