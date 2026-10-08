# Changelog

Every push to `main` is a release. Before pushing, add a `## [X.Y.Z] - YYYY-MM-DD`
section at the top with `- ` entries (minor for features, patch for fixes); if an
`## [Unreleased]` section is waiting, turn it into that section. GitHub tags it
and publishes the section as the release notes; a push or pull request
without one is refused (`[no release]` in the tip commit is the only exception).
Versions follow [Semantic Versioning](https://semver.org/). The full rule:
[StatusItemKit — Releases](https://github.com/nicholaspsmith/StatusItemKit#releases-every-push-is-one).

## [1.6.0] - 2026-10-08

- No user-visible changes.

## [1.5.0] - 2026-10-07

- No user-visible changes.

## [1.4.0] - 2026-10-06

- Choose where recordings are saved: **Settings ▸ Preferences… ▸ Save Location** (Downloads by default; falls back to Downloads if the folder is missing)
- Pressing a shortcut again right after starting a recording now always stops and saves it, instead of leaving the recording running

## [1.3.2] - 2026-10-06

- Ticking a checkbox in the menu no longer closes it: Settings ▸ Start at Login stays open when you turn it on or off

## [1.3.1] - 2026-10-05

- New app icon: Manny as he looks in the menu bar

## [1.3.0] - 2026-10-05

- New **Settings** submenu at the foot of the menu, the same one every Menumon app has: Preferences…, Icon and Start at Login now live there, with the version number at the bottom
- **Quit MacRecorder** stays at the top level, right below Settings, while idle and while recording

## [1.2.0] - 2026-10-05

- A real app icon: Manny, the camcorder from the menu bar, instead of a plain red record dot
- Manny's menu-bar icon has one lens, the one in his face (StatusItemKit 0.23.0)

## [1.1.0] - 2026-10-05

- Once a minute, while not recording, Manny focuses: his lens's iris closes in and opens again as a glint crosses the glass. His eyes stay put (he is the Unblinking Eye). He takes his turn after Lumen when several Menumon mascots are running, and sits still under Reduce Motion

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
