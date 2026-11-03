// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Nicholas Smith

import AppKit
import HotkeyKit
import MacRecorderCore
import StatusItemKit
import SwiftUI

/// Drives a `TriggerRecorder` and tracks which token is currently recording so
/// the view can update its button label. Pauses the global tap while capturing,
/// so pressing the *current* ⌘⇧5 is recorded as a new trigger rather than firing
/// an actual recording.
final class RecorderModel: ObservableObject {
    @Published var recordingToken: String?
    /// Whether a screen recording is running. Capturing a shortcut pauses the
    /// key tap, which would take away the shortcuts and Esc that stop it, so
    /// the Record buttons are off meanwhile.
    @Published var screenRecording = false
    private let recorder = TriggerRecorder()

    /// Wired by the app to stop/start the global HotkeyTap around capture.
    var onCaptureStart: (() -> Void)?
    var onCaptureEnd: (() -> Void)?

    func record(token: String, apply: @escaping (Trigger) -> Void) {
        guard !screenRecording else { return }
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

/// MacRecorder Preferences (menu ▸ Preferences…, ⌘,), on StatusItemKit's shared
/// window and form: General (Start at Login, the menu-bar icon), the two
/// recording shortcuts, then the save folder; the version at the foot.
struct PreferencesView: View {
    @ObservedObject var model: BindingsModel
    @ObservedObject var recorder: RecorderModel
    @ObservedObject var saveLocation: SaveLocation
    /// Redraws the menu-bar icon after the style changes.
    let onIconChange: () -> Void
    @State private var icon = RecorderStatusItem.IconStyle.current

    var body: some View {
        PreferencesForm {
            Section("General") {
                StartAtLoginToggle()
                LabeledContent("Menu Bar Icon") {
                    IconTilePicker(Self.iconChoices, selection: Binding(get: { icon }, set: { style in
                        icon = style
                        RecorderStatusItem.IconStyle.current = style
                        onIconChange()
                    }))
                }
            }

            Section {
                ForEach(model.bindings, id: \.token) { binding in
                    LabeledContent(label(for: binding.token)) {
                        HStack(spacing: 8) {
                            Text(TriggerFormatter.string(binding.trigger))
                                .monospaced()
                                .foregroundStyle(.secondary)
                            Button(recorder.recordingToken == binding.token ? "Press keys…" : "Record") {
                                recorder.record(token: binding.token) { trigger in
                                    model.setOverride(token: binding.token, trigger: trigger)
                                }
                            }
                            .disabled(recorder.screenRecording)
                            Button("Reset") { model.reset(token: binding.token) }
                                .disabled(!model.isOverridden(binding.token))
                        }
                    }
                }
            } header: {
                Text("Recording Shortcuts")
            } footer: {
                PreferencesNote(recorder.screenRecording
                    ? "Shortcuts can't be changed while a recording is running."
                    : "Stop and save a recording any time by pressing either shortcut again, "
                        + "Esc, or a left-click on the menu-bar icon. Esc is fixed.")
            }

            Section {
                LabeledContent("Folder") {
                    HStack(spacing: 8) {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: saveLocation.effectiveDirectory.path))
                            .resizable()
                            .frame(width: 16, height: 16)
                        Text(saveLocation.displayPath)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .help(saveLocation.effectiveDirectory.path)
                        Button("Choose…") { saveLocation.choose() }
                        Button("Reset") { saveLocation.reset() }
                            .disabled(!saveLocation.isCustom)
                    }
                }
            } header: {
                Text("Save Location")
            } footer: {
                PreferencesNote("If the folder is missing when a recording starts, it goes to ~/Downloads.")
            }
        }
    }

    private func label(for token: String) -> String {
        RecordingMode(token: token)?.label ?? token
    }

    /// Each style as it looks in the bar while idle. The tile is always dark,
    /// so the template symbol is drawn white rather than left to the text colour.
    private static let iconChoices: [IconTilePicker<RecorderStatusItem.IconStyle>.Choice] =
        RecorderStatusItem.IconStyle.allCases.map { style in
            let image: NSImage
            switch style {
            case .camcorder: image = CharacterIcon.camcorder(recording: false)
            case .symbol: image = whiteSymbol("record.circle")
            }
            return .init(id: style, title: style.title, image: image)
        }

    private static func whiteSymbol(_ name: String) -> NSImage {
        guard let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil) else { return NSImage() }
        return NSImage(size: symbol.size, flipped: false) { rect in
            symbol.draw(in: rect)
            NSColor.white.set()
            rect.fill(using: .sourceIn)
            return true
        }
    }
}
