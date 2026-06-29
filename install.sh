#!/usr/bin/env bash
# Build MacRecorder.app and symlink it into ~/Applications (rebuilds propagate;
# SMAppService accepts a symlink there for Start-at-Login).
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="MacRecorder.app"

"$SRC_DIR/scripts/build-app.sh"

mkdir -p "$HOME/Applications"
ln -sfn "$SRC_DIR/build/$APP_NAME" "$HOME/Applications/$APP_NAME"
echo "Linked $HOME/Applications/$APP_NAME -> $SRC_DIR/build/$APP_NAME"

open "$HOME/Applications/$APP_NAME"

cat <<'EOF'

MacRecorder is now running in the menu bar (the ◉ record glyph).

First-run setup — two one-time permission grants:
  1. Screen Recording (System Settings ▸ Privacy & Security ▸ Screen Recording)
     — required to capture the screen and system audio. The menu shows
     "⚠ Grant Screen Recording…" until allowed.
  2. Accessibility (System Settings ▸ Privacy & Security ▸ Accessibility)
     — required to intercept ⌘⇧5 before macOS's screenshot tool sees it. The
     menu shows "⚠ Grant Accessibility…" until allowed.
  Optional: menu ▸ Start at Login.

Use it:
  ⌘⇧5         start/stop recording the whole main display
  ⌘⌥⇧5        start a drag-to-select region recording (Esc cancels the picker)
  While recording, stop via ⌘⇧5 again, Esc, or a left-click on the menu-bar dot.
  Finished recordings are saved straight to ~/Downloads (no preview).

System audio is captured natively (ScreenCaptureKit) — no mic, no BlackHole, and
you keep hearing audio normally. Rebind either shortcut in Preferences.

Note: with a stable signing identity (StatusItemKit's setup-signing.sh) the
permission grants survive rebuilds; an ad-hoc build asks you to re-grant after
each rebuild (the code hash changes).
EOF
