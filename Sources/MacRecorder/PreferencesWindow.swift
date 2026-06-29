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

/// One row per recording mode: label, current shortcut, Record + Reset.
struct PreferencesView: View {
    @ObservedObject var model: BindingsModel
    @ObservedObject var recorder: RecorderModel

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
            Text("Stop a recording any time with the same shortcut, Esc, or a "
                 + "left-click on the menu-bar dot. Recordings save to ~/Downloads.")
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
    private let recorderModel = RecorderModel()

    init(model: BindingsModel, pauseTap: @escaping () -> Void, resumeTap: @escaping () -> Void) {
        self.model = model
        super.init()
        recorderModel.onCaptureStart = pauseTap
        recorderModel.onCaptureEnd = resumeTap
    }

    func show() {
        if window == nil {
            let host = NSHostingController(rootView: PreferencesView(model: model, recorder: recorderModel))
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
