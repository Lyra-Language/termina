#!/usr/bin/env bash
#
# Build Termina's programs into build/.
#
#   ./build.sh              # build/: the terminal (termina, and Termina.app on macOS) and
#                           # vttest; tools/check.sh plays the window headless
#
# Uses the sibling compiler, ../lyra/build/lyrac (run ../lyra/build.sh first), whose
# install layout puts `std/`, `bindings/`, `ui/` and the bindings' C halves (`lib/liblyra-*.a`)
# beside it. Override with $LYRAC. FreeType and HarfBuzz are linked wherever pkg-config finds
# them: a release points PKG_CONFIG_PATH at static ones first (tools/textlibs.sh).
set -euo pipefail

readonly ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LYRAC="${LYRAC:-$ROOT/../lyra/build/lyrac}"

if [ ! -x "$LYRAC" ]; then
  printf 'lyrac not found at %s — run ../lyra/build.sh, or set LYRAC\n' "$LYRAC" >&2
  exit 1
fi

# The Settings tab is markup (src/*.lui), generated into the module beside it by
# lui, which sits beside lyrac: a module older than its markup is refused here rather than
# built. `../lyra/build/lui src/<name>.lui` regenerates one.
readonly LUI="$(dirname "$LYRAC")/lui"
if [ -x "$LUI" ]; then
  "$LUI" --check "$ROOT"/src/*.lui
else
  printf 'lui not found beside lyrac: the markup is not checked against its modules\n' >&2
fi

mkdir -p "$ROOT/build"
"$LYRAC" build -o "$ROOT/build/termina" "$ROOT/src/termina.lyra"
"$LYRAC" build -o "$ROOT/build/vttest" "$ROOT/src/vttest.lyra"
# What the ImGui front end built, gone with it.
rm -f "$ROOT/build/termina-ui" "$ROOT/build/uitest" "$ROOT/build/menutest"

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
  # The usage strings are for the commands run in Termina, not Termina: macOS asks about a
  # command's camera, microphone, Apple Events, local network or folders as the app's that
  # started it, and shows the reason given here. The hardened runtime's half of the first
  # three is assets/Termina.entitlements, signed in by package.sh.
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
  <key>NSAppleEventsUsageDescription</key><string>A command run in Termina wants to control another app.</string>
  <key>NSMicrophoneUsageDescription</key><string>A command run in Termina wants to use the microphone.</string>
  <key>NSCameraUsageDescription</key><string>A command run in Termina wants to use the camera.</string>
  <key>NSLocalNetworkUsageDescription</key><string>A command run in Termina, such as ssh, wants to reach a device on your local network.</string>
  <key>NSDesktopFolderUsageDescription</key><string>A command run in Termina wants to use files in your Desktop folder.</string>
  <key>NSDocumentsFolderUsageDescription</key><string>A command run in Termina wants to use files in your Documents folder.</string>
  <key>NSDownloadsFolderUsageDescription</key><string>A command run in Termina wants to use files in your Downloads folder.</string>
  <key>NSRemovableVolumesUsageDescription</key><string>A command run in Termina wants to use files on a removable volume.</string>
  <key>NSNetworkVolumesUsageDescription</key><string>A command run in Termina wants to use files on a network volume.</string>
</dict>
</plist>
PLIST
fi
