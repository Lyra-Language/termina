#!/usr/bin/env bash
#
# Package what ./build.sh built as a release archive that runs without SDL3 installed:
#
#   ./package.sh <version>      # -> build/release/Termina-<version>-macos-arm64.zip
#                               #    build/release/termina-<version>-linux-<arch>.tar.gz
#
# **SDL3 goes with the program**, the one library Termina links that a machine may not
# have (the PTY, ImGui and FreeType are linked in). It is taken from where pkg-config's
# `sdl3` says, so a release builds it first (`tools/sdl3.sh`) and points PKG_CONFIG_PATH at
# it; run on a developer's machine, it bundles Homebrew's or the system's.
#
# - **macOS**: into `Termina.app/Contents/Frameworks/`, the program told to look there
#   (`@rpath`, with `@executable_path/../Frameworks` its rpath), and the bundle signed ad
#   hoc — the Apple silicon minimum, and what a changed binary needs after
#   install_name_tool. Not notarized: Gatekeeper asks once (right-click ▸ Open).
# - **Linux**: into `lib/` beside the program, found through an rpath of `$ORIGIN/lib`
#   (needs patchelf). The C library is the build machine's: built on Ubuntu 24.04, it runs
#   on glibc 2.39 and newer.
set -euo pipefail

readonly ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VERSION="${1:?usage: package.sh <version>}"
readonly OUT="$ROOT/build/release"
# The processor as releases name it: arm64 on both systems (Linux says aarch64).
ARCH="$(uname -m)"
[ "$ARCH" = aarch64 ] && ARCH=arm64
readonly ARCH

die() { printf 'package: %s\n' "$*" >&2; exit 1; }

[ -x "$ROOT/build/termina" ] || die "build/termina not found: run ./build.sh first"
SDL_LIBDIR="$(pkg-config --variable=libdir sdl3)" || die "SDL3 not found by pkg-config"
readonly SDL_LIBDIR
mkdir -p "$OUT"

case "$(uname -s)" in
  Darwin)
    readonly NAME="Termina-$VERSION-macos-$ARCH"
    readonly STAGE="$OUT/$NAME"
    rm -rf "$STAGE"
    mkdir -p "$STAGE"
    cp -R "$ROOT/build/Termina.app" "$STAGE/"
    readonly APP="$STAGE/Termina.app/Contents"
    readonly EXE="$APP/MacOS/termina"
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Info.plist"
    mkdir -p "$APP/Frameworks"
    cp "$SDL_LIBDIR/libSDL3.0.dylib" "$APP/Frameworks/"
    chmod u+w "$APP/Frameworks/libSDL3.0.dylib"
    install_name_tool -id @rpath/libSDL3.0.dylib "$APP/Frameworks/libSDL3.0.dylib"
    # Whatever path the program was linked against, it looks in the bundle instead.
    linked="$(otool -L "$EXE" | awk '/libSDL3/ { print $1 }')"
    [ -n "$linked" ] || die "build/termina does not link SDL3"
    install_name_tool -change "$linked" @rpath/libSDL3.0.dylib "$EXE"
    install_name_tool -add_rpath @executable_path/../Frameworks "$EXE"
    # Nothing but the system's and the bundle's may be left.
    if otool -L "$EXE" "$APP/Frameworks/libSDL3.0.dylib" | tail -n +2 |
      grep -v -e '^/' -e '/usr/lib/' -e '/System/Library/' -e '@rpath/' | grep -q .; then
      otool -L "$EXE" >&2
      die "the program links a library outside the system and the bundle"
    fi
    codesign --force --sign - "$APP/Frameworks/libSDL3.0.dylib"
    codesign --force --sign - "$STAGE/Termina.app"
    codesign --verify --strict "$STAGE/Termina.app"
    rm -f "$OUT/$NAME.zip"
    (cd "$STAGE" && ditto -c -k --keepParent Termina.app "$OUT/$NAME.zip")
    rm -rf "$STAGE"
    printf 'package: %s\n' "$OUT/$NAME.zip"
    ;;
  Linux)
    command -v patchelf >/dev/null 2>&1 || die "patchelf not found"
    readonly NAME="termina-$VERSION-linux-$ARCH"
    readonly STAGE="$OUT/$NAME"
    rm -rf "$STAGE"
    mkdir -p "$STAGE/lib"
    cp "$ROOT/build/termina" "$STAGE/"
    cp -L "$SDL_LIBDIR/libSDL3.so.0" "$STAGE/lib/"
    patchelf --set-rpath '$ORIGIN/lib' "$STAGE/termina"
    cp "$ROOT/LICENSE" "$ROOT/README.md" "$STAGE/"
    # SDL3 found in the archive, not wherever the build machine had it.
    ldd "$STAGE/termina" | grep -q "$STAGE/lib/libSDL3.so.0" ||
      { ldd "$STAGE/termina" >&2; die "the program does not find the bundled SDL3"; }
    tar -czf "$OUT/$NAME.tar.gz" -C "$OUT" "$NAME"
    rm -rf "$STAGE"
    printf 'package: %s\n' "$OUT/$NAME.tar.gz"
    ;;
  *) die "no packaging for $(uname -s)" ;;
esac
