# MacRecorder

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
- `docs/superpowers/specs/` — design spec.

See [`docs/superpowers/specs/2026-06-29-macrecorder-design.md`](docs/superpowers/specs/2026-06-29-macrecorder-design.md)
for the full design.
