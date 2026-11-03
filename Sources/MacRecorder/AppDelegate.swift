// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Nicholas Smith

import AppKit
import HotkeyKit
import MacRecorderCore
import StatusItemKit

/// Wires the menu-bar item, the global key tap, the region selector, and the
/// ScreenCaptureKit recorder together.
///
/// Recording is a simple state machine:
///   idle ──(⌘⇧5)────────────────▶ recording
///   idle ──(⌘⇧6)───▶ selectingRegion ──(drag)──▶ recording
///   recording ──(shortcut again / Esc / click dot)──▶ idle (file saved)
///
/// ⌘⇧5 is swallowed by the tap so macOS's Screenshot tool never appears. Esc is
/// only swallowed while recording; otherwise it passes through untouched.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private enum State { case idle, selectingRegion, recording }

    private var statusItem: RecorderStatusItem!
    private let model = BindingsModel()
    private let saveLocation = SaveLocation()
    private let recorder = Recorder()
    private let regionSelector = RegionSelector()
    private var tap: HotkeyTap!
    private var trustTimer: Timer?
    private var state: State = .idle {
        didSet { recorderModel.screenRecording = state == .recording }
    }
    /// The in-flight `recorder.start`. Stopping waits for it, so a shortcut
    /// pressed before ScreenCaptureKit has finished starting still stops and
    /// saves instead of leaving an orphaned capture running.
    private var startTask: Task<Void, Never>?
    /// Shortcut capture in Preferences. It pauses the key tap so the current
    /// ⌘⇧5 is recorded rather than starting a real recording, and resumes it after.
    private lazy var recorderModel: RecorderModel = {
        let m = RecorderModel()
        m.onCaptureStart = { [weak self] in self?.tap.stop() }
        m.onCaptureEnd = { [weak self] in self?.startTapIfPossible() }
        return m
    }()
    private lazy var prefs: PreferencesPane = {
        let pane = PreferencesPane(appName: "MacRecorder") { [unowned self] in
            PreferencesView(model: self.model, recorder: self.recorderModel, saveLocation: self.saveLocation,
                            onIconChange: { [weak self] in self?.statusItem.refresh() })
        }
        // Closing mid-capture would otherwise leave the key tap paused.
        pane.onClose = { [weak self] in self?.recorderModel.cancel() }
        return pane
    }()

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
        // A shortcut capture left pending in Preferences has the tap paused;
        // resume it, or the shortcuts and Esc couldn't stop this recording.
        recorderModel.cancel()
        state = .recording
        statusItem.setRecording(true)
        let scale = NSScreen.backingScale(for: displayID)
        let url = OutputPath.url(for: Date(), in: saveLocation.directory)
        startTask = Task { [weak self] in
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
        let pendingStart = startTask
        startTask = nil
        Task { [weak self] in
            guard let self else { return }
            await pendingStart?.value
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
        // Saved straight to the save folder with no preview; just log the path.
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
        // Every row here starts or stops a recording, or opens a window or a
        // dialog, so each closes the menu: a full-screen recording would
        // capture the open menu, and a region pick needs the whole screen.
        // These recording actions stay out of KeepOpenMenu by hand; it already
        // leaves "…" items and Quit alone. The options (icon, Start at Login)
        // live in the Preferences window.
        var recordingActions: [NSMenuItem] = []
        if state == .recording {
            recordingActions.append(actionItem("■ Stop Recording", #selector(menuStop)))
        } else {
            for mode in RecordingMode.allCases {
                let shortcut = trigger(for: mode).map { "    " + TriggerFormatter.string($0) } ?? ""
                let selector = (mode == .fullScreen) ? #selector(menuRecordFull) : #selector(menuRecordRegion)
                recordingActions.append(actionItem(mode.label + shortcut, selector))
            }
        }
        recordingActions.forEach(menu.addItem)

        if state != .recording {
            var warnings: [NSMenuItem] = []
            if !CGPreflightScreenCaptureAccess() {
                warnings.append(actionItem("⚠ Grant Screen Recording…", #selector(grantScreenRecording)))
            }
            if !(tap?.isTrusted ?? false) {
                warnings.append(actionItem("⚠ Grant Accessibility…", #selector(grantAccessibility)))
            }
            if !warnings.isEmpty {
                menu.addItem(.separator())
                warnings.forEach(menu.addItem)
            }
        }

        // Always offered, even mid-recording: the window turns its Record
        // buttons off then, since capturing a shortcut pauses the key tap.
        PreferencesMenu.addFooter(to: menu, appName: "MacRecorder") { [weak self] in self?.prefs.show() }
        KeepOpenMenu.apply(to: menu.items.filter { item in !recordingActions.contains { $0 === item } })
    }

    private func trigger(for mode: RecordingMode) -> Trigger? {
        model.bindings.first { $0.token == mode.token }?.trigger
    }

    private func actionItem(_ title: String, _ selector: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: "")
        item.target = self
        return item
    }

    // MARK: - Menu selectors

    @objc private func menuStop() { stopRecording() }
    @objc private func menuRecordFull() { if state == .idle { startFullScreen() } }
    @objc private func menuRecordRegion() { if state == .idle { startRegion() } }
    @objc private func grantScreenRecording() { CGRequestScreenCaptureAccess() }
    @objc private func grantAccessibility() { tap.requestTrust(); startTapIfPossible() }
}
