#!/usr/bin/env bash
#
# Fetch appimagetool and the AppImage runtime it wraps a program in, for this machine's
# processor, into <dir>: what package.sh makes a release's AppImage with.
#
#   tools/appimagetool.sh <dir>      # -> <dir>/appimagetool, <dir>/runtime
#
# **Pinned, SHA-256 checked**: appimagetool 1.9.1 and the type2 runtime 20251108, the hashes
# GitHub records for those releases' files. Given the runtime, appimagetool downloads
# nothing itself. A download that is not byte for byte the pinned one is refused. Move a
# version and its hashes together (`gh api repos/AppImage/appimagetool/releases/tags/<tag>`
# lists each file's digest).
set -euo pipefail

readonly TOOL_VERSION="1.9.1"
readonly RUNTIME_VERSION="20251108"

readonly DIR="$(mkdir -p "${1:?usage: tools/appimagetool.sh <dir>}" && cd "$1" && pwd)"

die() { printf 'tools/appimagetool: %s\n' "$*" >&2; exit 1; }

case "$(uname -m)" in
  x86_64)
    readonly ARCH=x86_64
    readonly TOOL_SHA256="ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0"
    readonly RUNTIME_SHA256="2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d"
    ;;
  aarch64 | arm64)
    readonly ARCH=aarch64
    readonly TOOL_SHA256="f0837e7448a0c1e4e650a93bb3e85802546e60654ef287576f46c71c126a9158"
    readonly RUNTIME_SHA256="00cbdfcf917cc6c0ff6d3347d59e0ca1f7f45a6df1a428a0d6d8a78664d87444"
    ;;
  *) die "no AppImage for $(uname -m)" ;;
esac

command -v curl >/dev/null 2>&1 || die "curl not found"

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1"; else shasum -a 256 "$1"; fi |
    cut -d' ' -f1
}

# fetch <url> <dest> <sha256>: download to <dest> unless it is already there with the
# right hash. A wrong download is removed, never left to be trusted later.
fetch() {
  if [ -f "$2" ] && [ "$(sha256 "$2")" = "$3" ]; then return; fi
  curl -fsSL --retry 2 -o "$2.part" "$1" || { rm -f "$2.part"; die "download failed: $1"; }
  local got
  got="$(sha256 "$2.part")"
  [ "$got" = "$3" ] || { rm -f "$2.part"; die "checksum mismatch for $1 (got $got)"; }
  mv "$2.part" "$2"
}

fetch "https://github.com/AppImage/appimagetool/releases/download/$TOOL_VERSION/appimagetool-$ARCH.AppImage" \
  "$DIR/appimagetool" "$TOOL_SHA256"
fetch "https://github.com/AppImage/type2-runtime/releases/download/$RUNTIME_VERSION/runtime-$ARCH" \
  "$DIR/runtime" "$RUNTIME_SHA256"
chmod +x "$DIR/appimagetool"
printf 'tools/appimagetool: appimagetool %s and runtime %s in %s\n' "$TOOL_VERSION" "$RUNTIME_VERSION" "$DIR"
