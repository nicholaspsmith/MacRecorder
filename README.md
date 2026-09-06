# MacRecorder

<p align="center"><img src="docs/mascot.png" width="160" alt="MacRecorder mascot, from the Menubarn widget library"></p>

A tiny standalone macOS menu-bar app that records the screen **with system
audio** — the one thing QuickTime's screen recording can't do — triggered by
**⌘⇧5** (the shortcut macOS normally gives the Screenshot tool). Recordings are
written **straight to `~/Downloads`**, skipping the post-recording preview.

Built on [StatusItemKit](https://github.com/nicholaspsmith/StatusItemKit) (the
menu-bar shell) and [HotkeyKit](https://github.com/nicholaspsmith/HotkeyKit)
(the global key-tap engine), the same way as
[KeyLight](https://github.com/nicholaspsmith/keylight-menubar).

## What it does

| Trigger (default) | Action |
|-------------------|--------|
| `⌘⇧5` | Start/stop recording the **whole main display** |
| `⌘⇧6` | Start a **drag-to-select region** recording (Esc cancels the picker) |

While recording, **stop** any of three ways: press the mode's shortcut again,
press **Esc**, or **left-click the red menu-bar dot**. The finished `.mov` lands
in `~/Downloads` — no preview, no thumbnail.

- **System audio only** — captured natively by ScreenCaptureKit. No microphone,
  no BlackHole / virtual device, and you keep hearing audio normally.
- Both shortcuts are **rebindable** in Preferences.

## How it works

- **ScreenCaptureKit** (`SCStream` + `SCRecordingOutput`, macOS 15+) captures the
  display plus system audio (`capturesAudio` on, `excludesCurrentProcessAudio`
  on, mic untouched) and writes the `.mov` directly — no `AVAssetWriter`. Region
  recording crops via `SCStreamConfiguration.sourceRect`.
- **HotkeyKit** owns a `CGEventTap` that intercepts ⌘⇧5 and **swallows** it, so
  macOS's screenshot toolbar never appears.
- **StatusItemKit** provides the menu-bar shell, the start-at-login toggle
  (`SMAppService`), and the icon drawing.

## Install

Requires the sibling repos `../StatusItemKit` and `../HotkeyKit` checked out
next to this one.

```sh
./install.sh
```

This builds `MacRecorder.app`, symlinks it into `~/Applications`, and launches
it. Grant **Screen Recording** and **Accessibility** when prompted (each is a
one-time grant; the menu shows a "⚠ Grant…" item until you do).

## Layout

- `Sources/MacRecorderCore` — pure, unit-tested logic (modes, default bindings,
  output-path formatting).
- `Sources/MacRecorder` — the app (recorder, region selector, status item,
  hotkeys, preferences).
- `Resources/bundle/AppIcon.icns` — placeholder app icon (red record dot on a
  dark squircle). Regenerate with `swift scripts/make-icon.swift`, or drop in
  real artwork to replace it.
- `docs/superpowers/specs/` — design spec.

See [`docs/superpowers/specs/2026-06-29-macrecorder-design.md`](docs/superpowers/specs/2026-06-29-macrecorder-design.md)
for the full design.

## Why not a SwiftBar plugin?

This is a standalone `.app` built on [StatusItemKit](https://github.com/nicholaspsmith/StatusItemKit), not a script under a plugin host: no SwiftBar to install, a real AppKit menu instead of rendered stdout, event-driven updates instead of a re-run timer, and an icon that keeps its place in the bar. Recording the screen with system audio uses ScreenCaptureKit, and the global ⌘⇧5 hotkey comes from HotkeyKit's `CGEventTap`; neither is reachable from a plugin script. The full comparison is in [StatusItemKit's README](https://github.com/nicholaspsmith/StatusItemKit#why-not-swiftbar).

## The menu-bar suite

Part of a suite of macOS menu-bar apps that share one framework, one
build-and-sign script, and one installer. They are designed to sit in the
same bar together: consistent menus, a common **Icon** picker for shape and
colour, and cooperative hiding so no icon strands another.

| App | What it does |
|---|---|
| [Claude Usage](https://github.com/nicholaspsmith/claude-usage-menubar) | Claude Code plan limits, resets, and live agent sessions |
| [Apollo Monitor](https://github.com/nicholaspsmith/apollo-monitor-menubar) | Universal Audio Apollo monitor level, plus a UA process watchdog |
| [Battery Time](https://github.com/nicholaspsmith/battery-time-menubar) | Time remaining, power mode, and 24h usage |
| [VPN & DNS](https://github.com/nicholaspsmith/vpn-dns-menubar) | One dot for Mullvad + Tailscale state, with a DNS watcher |
| [Process Monitor](https://github.com/nicholaspsmith/MacOS_Process_Monitor) | Process-count sparkline against the per-UID limit |
| [KeyLight](https://github.com/nicholaspsmith/keylight-menubar) | Ctrl+brightness keys remapped to keyboard backlight |
| **MacRecorder** | Screen recording with system audio |
| [Media Tracking Killer](https://github.com/nicholaspsmith/media-tracking-killer-menubar) | Kills Apple's media tracking daemons |
| [Download Recycler](https://github.com/nicholaspsmith/download-recycler-menubar) | Sweeps stale files out of ~/Downloads |
| [Curtain](https://github.com/nicholaspsmith/menubar-curtain) | Hides a block of status icons by width, so it cannot strand one |

| Framework | |
|---|---|
| [StatusItemKit](https://github.com/nicholaspsmith/StatusItemKit) | Status-item lifecycle, polling, menus, meter icons, the shared Icon picker |
| [HotkeyKit](https://github.com/nicholaspsmith/HotkeyKit) | CGEventTap engine for intercepting and remapping global keys |

Install the whole suite on a fresh Mac with
[macOS Dev Environment Setup](https://github.com/nicholaspsmith/MacOS-Dev-Environment-Setup):

```bash
git clone https://github.com/nicholaspsmith/MacOS-Dev-Environment-Setup.git
cd MacOS-Dev-Environment-Setup && ./bootstrap.sh --all
```
