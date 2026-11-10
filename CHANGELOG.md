# Changelog

Every push to `main` is a release. Before pushing, add a `## [X.Y.Z] - YYYY-MM-DD`
section at the top with `- ` entries (minor for features, patch for fixes); if an
`## [Unreleased]` section is waiting, turn it into that section. GitHub tags it
and publishes the section as the release notes; a push or pull request
without one is refused (`[no release]` in the tip commit is the only exception).
Versions follow [Semantic Versioning](https://semver.org/). The full rule:
[StatusItemKit — Releases](https://github.com/nicholaspsmith/StatusItemKit#releases-every-push-is-one).

## [1.20.0] - 2026-11-10

- Updated StatusItemKit to 0.40.0
- `IconTilePicker` can space its tiles evenly: given a `columnWidth` (`IconTilePicker.columnWidth(for:)` spreads them across the form) each tile sits in a column of that width whatever its name, and a long name shrinks slightly to fit instead of being cut off.

## [1.19.0] - 2026-11-10

- Updated StatusItemKit to 0.39.0
- New `MeterColor.healthAdaptive` (and `healthOnDark`): the usage ramp for a menu's bars and text. It is bright on a dark menu and deep on a light one, so it reads on both.
- The owl's pupils stand out from his eyes at every usage. The green-to-red ramp is now a brighter green (`#00860B`) deepening through orange to a strong red (`#A50000`), in place of a light orange-red that washed out against a tired, pink eye.

## [1.18.2] - 2026-11-03

- Updated StatusItemKit to 0.38.4
- A folding menu section with read-only rows (Battery Stats) no longer widens the menu when it opens. The menu starts just wide enough for the section's longest line, so its width stays the same whether the section is open or folded.

## [1.18.1] - 2026-11-03

- Updated StatusItemKit to 0.38.3
- Fixed a bug where clicking a folding menu heading did nothing in menus that auto-enable their items.

## [1.18.0] - 2026-11-03

- The status dot in the keep-open menu now aligns with other items instead of being pushed to the right.
- Long menu rows with status dots are no longer clipped at the end.
- The Settings submenu has been replaced by a standard Preferences window (⌘,) with a grouped form layout.
- Selecting an option in the keep-open menu no longer closes the menu, allowing for easier selection.
- Menu sections can now be folded away using a chevron heading.
- Read-only menu rows are now displayed in grey text.

## [1.17.0] - 2026-11-03

- Settings move into a **MacRecorder Preferences** window (menu ▸ Preferences…, ⌘,), laid out like Mac Daddy's and the other Menumon apps': General (Start at Login, and the menu-bar icon as Camcorder and Symbol tiles), Recording Shortcuts, Save Location, and the version at the foot. Esc or ⌘W closes it.
- The menu now ends with Preferences… and Quit MacRecorder. The Settings and Icon submenus are gone; their options are in the window.
- Preferences… is in the menu while recording too. The shortcut Record buttons are off until the recording stops, since capturing a shortcut pauses the keys that stop it.
- Every row left in the menu starts or stops a recording or opens a window or dialog, so clicking one still closes the menu (a full-screen recording would otherwise capture it).

## [1.16.0] - 2026-11-02

- Holding modifier keys like ⌘⌥ now works correctly for navigation keys (arrows, Home, End, Page Up, Page Down, Forward Delete, Help); the `fn` flag is no longer incorrectly included in these hotkey combinations.
- The Apollo Monitor icon in the menu bar now displays the current level in grey when Accessibility permissions are not granted or the engine is unreachable, instead of going dark, so you can still see the level while it is unchangeable.

## [1.15.0] - 2026-11-02

- No user-visible changes.

## [1.14.0] - 2026-11-01

- No user-visible changes.

## [1.13.0] - 2026-10-20

### Changed

- Icon ▸ (Camcorder / Symbol) moves out of Settings ▸ into the main menu, directly below Settings and above Quit MacRecorder. Settings keeps Preferences…, Start at Login and the version; while recording, Icon is still offered below Settings. Needs StatusItemKit 0.35.0 (`SettingsMenu.addFooter(belowSettings:)`)

## [1.12.1] - 2026-10-20

- `install.sh` now hands the install to parity on a Mac parity syncs, instead of building a second copy of the app that macOS could launch in place of parity's. `PARITY=off ./install.sh` still builds it locally.

## [1.12.0] - 2026-10-20

- Menu bar icons now update more smoothly with significantly less impact on system performance.

## [1.11.0] - 2026-10-15

- The menu bar owl icon now supports custom pupil colors, allowing users to choose their preferred eye color instead of the default green-to-red gradient.

## [1.10.0] - 2026-10-15

- Carol now sleeps in the menu bar, with her eyes closing, body breathing, and Zs floating above her.

## [1.9.0] - 2026-10-15

- Carol's headband no longer gets cut off at the top of the menu bar icon, and her head movement is now smoother and stays within the icon's boundaries.
- Carol's walking animation is now more responsive to her speed, with smoother transitions and higher frame rates for a more fluid appearance in the menu bar.

## [1.8.0] - 2026-10-15

- The caterpillar icon now supports a walking animation, featuring a smooth, rolling motion that is distinct from its previous running animation.

## [1.7.0] - 2026-10-09

- No user-visible changes.

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
