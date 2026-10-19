#!/usr/bin/env bash
#
# Build Termina's programs into build/.
#
#   ./build.sh              # build/: the terminal (termina, and Termina.app on macOS) and
#                           # the tests (vttest; uitest, the command line on a headless host;
#                           # menutest, the Mac's menu bar)
#
# Uses the sibling compiler, ../lyra/build/lyrac (run ../lyra/build.sh first), whose
# install layout puts `std/`, `bindings/` and the bindings' C halves (`lib/liblyra-pty.a`,
# `lib/liblyra-imgui.a`) beside it. Override with $LYRAC.
set -euo pipefail

readonly ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LYRAC="${LYRAC:-$ROOT/../lyra/build/lyrac}"

if [ ! -x "$LYRAC" ]; then
  printf 'lyrac not found at %s — run ../lyra/build.sh, or set LYRAC\n' "$LYRAC" >&2
  exit 1
fi

mkdir -p "$ROOT/build"
"$LYRAC" build -o "$ROOT/build/termina" "$ROOT/src/termina.lyra"
"$LYRAC" build -o "$ROOT/build/vttest" "$ROOT/src/vttest.lyra"
"$LYRAC" build -o "$ROOT/build/uitest" "$ROOT/src/uitest.lyra"
"$LYRAC" build -o "$ROOT/build/menutest" "$ROOT/src/menutest.lyra"

# **On macOS, also an app** — build/Termina.app, the same program in a bundle — so that it
# opens from Finder and the Dock, and the system (and anything driving it, such as
# accessibility tools) sees it as an application rather than a bare process.
if [ "$(uname -s)" = Darwin ]; then
  readonly APP="$ROOT/build/Termina.app/Contents"
  mkdir -p "$APP/MacOS" "$APP/Resources"
  # The icon: assets/Termina.icns, made from assets/termina.svg (assets/README.md says how).
  cp "$ROOT/assets/Termina.icns" "$APP/Resources/Termina.icns"
  # Swapped in by rename, never overwritten in place: a copy of the app that is running
  # keeps the file it started from (macOS kills a process whose code changes under it).
  cp "$ROOT/build/termina" "$APP/MacOS/termina.new"
  mv -f "$APP/MacOS/termina.new" "$APP/MacOS/termina"
  cat > "$APP/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Termina</string>
  <key>CFBundleIdentifier</key><string>dev.lyra-language.termina</string>
  <key>CFBundleExecutable</key><string>termina</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleIconFile</key><string>Termina</string>
  <key>CFBundleShortVersionString</key><string>0.1</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST
fi
