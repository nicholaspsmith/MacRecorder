// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Nicholas Smith

import AppKit
import HotkeyKit
import MacRecorderCore
import SwiftUI

/// Drives a `TriggerRecorder` and tracks which token is currently recording so
/// the view can update its button label. Pauses the global tap while capturing,
/// so pressing the *current* ⌘⇧5 is recorded as a new trigger rather than firing
/// an actual recording.
final class RecorderModel: ObservableObject {
    @Published var recordingToken: String?
    private let recorder = TriggerRecorder()

    /// Wired by the app to stop/start the global HotkeyTap around capture.
    var onCaptureStart: (() -> Void)?
    var onCaptureEnd: (() -> Void)?

    func record(token: String, apply: @escaping (Trigger) -> Void) {
        if recordingToken != nil { cancel() }
        recordingToken = token
        onCaptureStart?()
        recorder.start { [weak self] trigger in
            apply(trigger)
            self?.recordingToken = nil
            self?.onCaptureEnd?()
        }
    }

    func cancel() {
        recorder.stop()
        let wasRecording = recordingToken != nil
        recordingToken = nil
        if wasRecording { onCaptureEnd?() }
    }
}

/// One row per recording mode (label, current shortcut, Record + Reset), then
/// the folder recordings are saved to.
struct PreferencesView: View {
    @ObservedObject var model: BindingsModel
    @ObservedObject var recorder: RecorderModel
    @ObservedObject var saveLocation: SaveLocation

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recording Shortcuts")
                .font(.headline)

            ForEach(model.bindings, id: \.token) { binding in
                HStack(spacing: 10) {
                    Text(label(for: binding.token))
                        .frame(width: 170, alignment: .leading)
                    Spacer()
                    Text(TriggerFormatter.string(binding.trigger))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(minWidth: 90, alignment: .trailing)
                    Button(recorder.recordingToken == binding.token ? "Press keys…" : "Record") {
                        recorder.record(token: binding.token) { trigger in
                            model.setOverride(token: binding.token, trigger: trigger)
                        }
                    }
                    Button("Reset") { model.reset(token: binding.token) }
                        .disabled(!model.isOverridden(binding.token))
                }
            }

            Divider()
            Text("Save Location")
                .font(.headline)

            HStack(spacing: 10) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: saveLocation.effectiveDirectory.path))
                    .resizable()
                    .frame(width: 16, height: 16)
                Text(saveLocation.displayPath)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(saveLocation.effectiveDirectory.path)
                Spacer()
                Button("Choose…") { saveLocation.choose() }
                Button("Reset") { saveLocation.reset() }
                    .disabled(!saveLocation.isCustom)
            }

            Divider()
            Text("Stop and save a recording any time by pressing either shortcut "
                 + "again, Esc, or a left-click on the menu-bar dot. If the save "
                 + "folder is missing when a recording starts, it goes to ~/Downloads.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(width: 460)
    }

    private func label(for token: String) -> String {
        RecordingMode(token: token)?.label ?? token
    }
}

/// Lazily creates and shows the preferences window. Pauses/resumes the global
/// tap during shortcut capture and cancels any in-progress capture on close.
final class PreferencesWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private let model: BindingsModel
    private let saveLocation: SaveLocation
    private let recorderModel = RecorderModel()

    init(model: BindingsModel, saveLocation: SaveLocation, pauseTap: @escaping () -> Void, resumeTap: @escaping () -> Void) {
        self.model = model
        self.saveLocation = saveLocation
        super.init()
        recorderModel.onCaptureStart = pauseTap
        recorderModel.onCaptureEnd = resumeTap
    }

    func show() {
        if window == nil {
            let host = NSHostingController(rootView: PreferencesView(model: model, recorder: recorderModel, saveLocation: saveLocation))
            let win = NSWindow(contentViewController: host)
            win.title = "MacRecorder Preferences"
            win.styleMask = [.titled, .closable]
            win.isReleasedWhenClosed = false
            win.delegate = self
            window = win
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        recorderModel.cancel() // ensure the tap resumes if a capture was pending
    }
}
