# MacRecorder — design

**Date:** 2026-06-29
**Status:** approved

## Problem

QuickTime's screen recording can't capture **system audio**. The goal is a
one-keystroke screen recorder that captures the screen **plus system audio only**
(no microphone), stops on command, and writes the file **straight to
`~/Downloads`** — skipping macOS's post-recording preview/thumbnail. The trigger
is **⌘⇧5**, the shortcut macOS normally maps to the Screenshot tool.

## Approach

A standalone `LSUIElement` Swift menu-bar app — `~/Code/MacRecorder` →
`MacRecorder.app`, symlinked into `~/Applications` — following the existing
KeyLight pattern (StatusItemKit shell + HotkeyKit global key tap, SMAppService
start-at-login, the shared `make-app.sh` bundler with a stable signing identity).

Capture uses **ScreenCaptureKit**, which on macOS 15+ captures **system audio
natively** (no virtual audio device, no rerouting — audio keeps playing through
the speakers normally) and writes the file directly via **`SCRecordingOutput`**
(no manual `AVAssetWriter`). System audio is enabled with `capturesAudio = true`
and `excludesCurrentProcessAudio = true`; the microphone is never touched.

⌘⇧5 is intercepted and **swallowed** by HotkeyKit's `CGEventTap` before
Screenshot.app sees it (the same mechanism KeyLight uses for the brightness keys),
so the native screenshot toolbar never appears.

## Features

Two recording modes, each with a menu item **and** a user-reassignable global
shortcut:

| Mode | Default shortcut | Behavior |
|------|------------------|----------|
| Record Entire Screen | ⌘⇧5 | Records the whole **main** display. |
| Record Selected Area | ⌘⇧6 | Drag a rectangle (crosshair overlay) to record just that region. Esc cancels the picker. |

Stop a recording three ways (all fixed): re-press the mode's shortcut (toggle),
press **Esc**, or **left-click the menu-bar dot**. On stop the `.mov` is finalized
into `~/Downloads`; no preview is shown.

## Components

- **`MacRecorderCore`** (pure, unit-tested, depends only on HotkeyKit types):
  - `RecordingMode` — `.fullScreen` / `.region`, with binding tokens + UI labels.
  - `BindingStore` — built-in default `Binding`s for the two modes + `resolve(overrides:)`
    merge logic (mirrors KeyLightCore).
  - `OutputPath` — pure filename builder (`Screen Recording <date> at <time>.mov`)
    and `~/Downloads` URL helper.
- **`Recorder`** — ScreenCaptureKit wrapper: `SCStream` + `SCRecordingOutput`,
  full display or `sourceRect` crop, `.mov`/HEVC, `start`/`stop`.
- **`RegionSelector`** — transparent full-screen overlay window(s) with crosshair
  + drag-to-draw selection; returns `(SCDisplay, sourceRect in display points)` or
  cancels on Esc.
- **`HotkeyController`** — owns the HotkeyKit `HotkeyTap`; registers the two mode
  triggers (rebindable) plus a fixed Esc-to-stop; routes matches to the app.
- **`BindingsModel`** — single source of truth for the two mode triggers; persists
  user overrides to `UserDefaults`; notifies the tap + prefs UI on change.
- **`RecorderStatusItem`** — owns the `NSStatusItem`: builds the menu when idle,
  stops the recording on a left-click while recording, shows a red dot while
  active. (A bespoke status item rather than StatusItemKit's menu-only
  `StatusItemController`, because MacRecorder needs the two-state click behavior;
  it still reuses StatusItemKit's `MeterIcon`, `LoginItem`, etc.)
- **`PreferencesWindow`** — SwiftUI rows to rebind each mode's shortcut (reuses
  HotkeyKit's `TriggerRecorder`); `TriggerFormatter` renders glyph strings.
- **App / `main.swift`** — `NSApplicationDelegate` wiring; permission gating for
  **Screen Recording** (`CGPreflightScreenCaptureAccess` / `CGRequestScreenCaptureAccess`)
  and **Accessibility** (`AXIsProcessTrusted`), each surfaced as a "⚠ Grant…"
  menu item like KeyLight.

## Data flow

1. Key tap matches a mode trigger → `start(mode:)`.
2. `.region` → `RegionSelector` overlay → on mouse-up, `(display, rect)`; `.fullScreen`
   → main display, no crop.
3. `Recorder.start` configures `SCStream` (audio on, mic off, optional `sourceRect`)
   + `SCRecordingOutput(outputURL: ~/Downloads/…mov)` → `startCapture`.
4. Stop trigger (toggle / Esc / click) → `Recorder.stop` → `stopCapture` finalizes
   the file. Icon returns to idle.

## Error handling

- Missing **Screen Recording** permission → `CGRequestScreenCaptureAccess()` prompt
  + "⚠ Grant Screen Recording…" menu item; recording is a no-op until granted.
- Missing **Accessibility** → tap can't run; "⚠ Grant Accessibility…" + a
  recheck timer re-arms the tap once trusted (KeyLight's pattern).
- `SCRecordingOutput` failure (delegate `didFailWithError`) → reset to idle, log;
  no partial-preview UI.

## Testing

- Unit tests (`MacRecorderCoreTests`): `BindingStore.resolve` override/merge, and
  `OutputPath` filename formatting for a fixed `Date`.
- Capture, region overlay, hotkey swallowing, and permission flows are verified by
  running the app (system-integration paths, not unit-testable).

## Out of scope (YAGNI)

Microphone capture, picking a non-main display for full-screen mode (architecture
leaves room to add it), multi-display region spanning, in-app editing/trimming,
configurable codec/fps UI, recording-duration readout in the menu bar.
