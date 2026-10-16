#!/usr/bin/env bash
#
# Build Sulafat's programs into build/.
#
#   ./build.sh              # build/: the terminal (sulafat) and the VT tests (vttest)
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
"$LYRAC" build -o "$ROOT/build/sulafat" "$ROOT/src/sulafat.lyra"
"$LYRAC" build -o "$ROOT/build/vttest" "$ROOT/src/vttest.lyra"
