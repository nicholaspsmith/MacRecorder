// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Nicholas Smith

import AppKit
import Combine
import MacRecorderCore

/// Where finished recordings are saved. Persists the chosen folder's path in
/// `UserDefaults`; nil means the default, ~/Downloads. The app isn't sandboxed,
/// so a plain path is enough (no security-scoped bookmark).
final class SaveLocation: ObservableObject {
    @Published private(set) var directory: URL?
    private let defaultsKey = "saveDirectory"

    init() {
        directory = UserDefaults.standard.string(forKey: defaultsKey)
            .map { URL(fileURLWithPath: $0, isDirectory: true) }
    }

    /// The folder recordings go to right now, for display.
    var effectiveDirectory: URL { directory ?? OutputPath.downloadsDirectory }

    /// "~/Movies/Recordings"-style path for display.
    var displayPath: String { (effectiveDirectory.path as NSString).abbreviatingWithTildeInPath }

    var isCustom: Bool { directory != nil }

    /// Ask for a folder with an open panel; keeps the current one on cancel.
    func choose() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.message = "Choose where MacRecorder saves recordings"
        panel.directoryURL = effectiveDirectory
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        set(url)
    }

    func reset() { set(nil) }

    private func set(_ url: URL?) {
        directory = url
        if let url {
            UserDefaults.standard.set(url.path, forKey: defaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: defaultsKey)
        }
    }
}
