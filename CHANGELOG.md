# Changelog

Every push to `main` is a release. Before pushing, add a `## [X.Y.Z] - YYYY-MM-DD`
section at the top with `- ` entries (minor for features, patch for fixes); if an
`## [Unreleased]` section is waiting, turn it into that section. GitHub tags it
and publishes the section as the release notes; a push or pull request
without one is refused (`[no release]` in the tip commit is the only exception).
Versions follow [Semantic Versioning](https://semver.org/). The full rule:
[StatusItemKit — Releases](https://github.com/nicholaspsmith/StatusItemKit#releases-every-push-is-one).

## [1.0.3] - 2026-09-28

- New menu-bar icon: a blue camcorder whose record light and lens glow red while recording

## [1.0.2] - 2026-09-28

- `install.sh` now asks whether to turn on Start at Login (skipped when it is already on, or when there is no terminal to ask in) instead of turning it on unasked, then relaunches the app, quitting any running copy first so the new build takes over

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
