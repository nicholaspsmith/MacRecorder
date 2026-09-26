# Changelog

Every push to `main` is a release. Add a `## [X.Y.Z] - YYYY-MM-DD` section at
the top (minor for features, patch for fixes); GitHub tags it and publishes
the section as the release notes. Versions follow [Semantic
Versioning](https://semver.org/).

## [1.0.1] - 2026-09-23

- chore: regenerate the menu-bar icon image

## [1.0.0] - 2026-09-20

- LICENSE: name the copyright holder above the MPL text
- License: Mozilla Public License 2.0
- docs: document the --login flag
- feat: --login on|off|status, and register Start at Login on install
- fix: menu runs via NSMenu.popUp under the button
- fix: keep the popped menu attached until tracking ends
- fix: status-item click fires on mouse down so the menu tracks the press
- docs: Curtain is now Barn
- docs: Apollo Monitor described without the vendor name
- docs: the camcorder face icon
- docs: the character menu-bar icon, rendered from code, and what its states mean
- feat: camcorder icon with a red light while recording (Icon ▸ Symbol restores the old one)
- docs: mention the Menubarn widget library
- docs: why a standalone app beats a SwiftBar plugin
- docs: add the Menubarn mascot to the README
- Advertise the menu-bar suite
- Add a placeholder app icon
- Make ⌘⇧6 the region-recording shortcut
- Add Preferences window to rebind the two shortcuts
- Add the recorder app: capture, region select, hotkeys, menu bar
- Initial commit: MacRecorder — scaffold, design spec, MacRecorderCore
