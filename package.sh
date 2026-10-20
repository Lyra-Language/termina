#!/usr/bin/env bash
#
# Package what ./build.sh built as a release archive that runs without SDL3 installed:
#
#   ./package.sh <version>      # -> build/release/Termina-<version>-macos-arm64.zip
#                               #    build/release/termina-<version>-linux-<arch>.tar.gz
#   TERMINA_APPIMAGE=1 ./package.sh <version>   # on Linux, and
#                               #    build/release/Termina-<version>-linux-<arch>.AppImage
#
# **SDL3 goes with the program**, the one library Termina links that a machine may not
# have (the PTY, ImGui and FreeType are linked in). It is taken from where pkg-config's
# `sdl3` says, so a release builds it first (`tools/sdl3.sh`) and points PKG_CONFIG_PATH at
# it; run on a developer's machine, it bundles Homebrew's or the system's.
#
# - **macOS**: into `Termina.app/Contents/Frameworks/`, the program told to look there
#   (`@rpath`, with `@executable_path/../Frameworks` its rpath), and the bundle signed —
#   which a changed binary needs after install_name_tool:
#   - with **`TERMINA_SIGN_IDENTITY`** (a Developer ID Application identity in a
#     keychain), for the hardened runtime with a secure timestamp, as notarization asks,
#     and the entitlements its commands need (`assets/Termina.entitlements`);
#     and with **`TERMINA_NOTARY_KEY`**, `TERMINA_NOTARY_KEY_ID` and
#     `TERMINA_NOTARY_ISSUER` too (an App Store Connect API key: the `.p8` file's path, its
#     id, its issuer), notarized by Apple and the ticket stapled to the app, so it opens
#     with no warning, offline too;
#   - without, ad hoc — the Apple silicon minimum. Gatekeeper then asks once
#     (right-click ▸ Open).
# - **Linux**: into `lib/` beside the program, found through an rpath of `$ORIGIN/lib`
#   (needs patchelf). The C library is the build machine's: built on Ubuntu 24.04, it runs
#   on glibc 2.39 and newer. **With `TERMINA_APPIMAGE`, an AppImage too**: the same
#   directory as an AppDir — `AppRun` a link to the program, the desktop entry and icon
#   beside it — made by the pinned appimagetool (`tools/appimagetool.sh`, into
#   build/deps/appimage). No sandbox and no `LD_LIBRARY_PATH`, so the shell Termina starts
#   is the user's own, with nothing of the AppImage's in its libraries.
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
    # The library first: a bundle's signature covers what is inside it, signed already.
    if [ -n "${TERMINA_SIGN_IDENTITY:-}" ]; then
      codesign --force --options runtime --timestamp --sign "$TERMINA_SIGN_IDENTITY" \
        "$APP/Frameworks/libSDL3.0.dylib"
      # The app with what its commands may ask for (assets/Termina.entitlements); the
      # library with nothing, as entitlements belong to the program.
      codesign --force --options runtime --timestamp --sign "$TERMINA_SIGN_IDENTITY" \
        --entitlements "$ROOT/assets/Termina.entitlements" "$STAGE/Termina.app"
    else
      codesign --force --sign - "$APP/Frameworks/libSDL3.0.dylib"
      codesign --force --sign - "$STAGE/Termina.app"
    fi
    codesign --verify --strict --deep "$STAGE/Termina.app"
    rm -f "$OUT/$NAME.zip"
    (cd "$STAGE" && ditto -c -k --keepParent Termina.app "$OUT/$NAME.zip")
    if [ -n "${TERMINA_SIGN_IDENTITY:-}" ] && [ -n "${TERMINA_NOTARY_KEY:-}" ]; then
      # Apple's service checks the zip and answers for the app; the ticket is stapled to
      # the app itself, so the zip is made again around it.
      notary=(--key "$TERMINA_NOTARY_KEY" --key-id "${TERMINA_NOTARY_KEY_ID:?}"
        --issuer "${TERMINA_NOTARY_ISSUER:?}")
      answer="$(xcrun notarytool submit "$OUT/$NAME.zip" --wait "${notary[@]}")"
      printf '%s\n' "$answer"
      # An app Apple refuses still ends the wait: the answer says so, and the log says why.
      if ! printf '%s\n' "$answer" | grep -q 'status: Accepted'; then
        id="$(printf '%s\n' "$answer" | awk '/^ *id:/ { print $2; exit }')"
        [ -n "$id" ] && xcrun notarytool log "$id" "${notary[@]}" >&2
        die "notarization did not accept the app"
      fi
      xcrun stapler staple "$STAGE/Termina.app"
      spctl --assess --type execute --verbose=2 "$STAGE/Termina.app"
      rm -f "$OUT/$NAME.zip"
      (cd "$STAGE" && ditto -c -k --keepParent Termina.app "$OUT/$NAME.zip")
      signed="notarized"
    elif [ -n "${TERMINA_SIGN_IDENTITY:-}" ]; then
      signed="signed, not notarized"
    else
      signed="signed ad hoc"
    fi
    rm -rf "$STAGE"
    printf 'package: %s (%s)\n' "$OUT/$NAME.zip" "$signed"
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
    # SDL3 found in the archive, not wherever the build machine had it — asked as a user's
    # machine would ask, without the LD_LIBRARY_PATH a build may set, which outranks the
    # rpath.
    env -u LD_LIBRARY_PATH ldd "$STAGE/termina" | grep -q "$STAGE/lib/libSDL3.so.0" || {
      env -u LD_LIBRARY_PATH ldd "$STAGE/termina" >&2
      die "the program does not find the bundled SDL3"
    }
    tar -czf "$OUT/$NAME.tar.gz" -C "$OUT" "$NAME"
    printf 'package: %s\n' "$OUT/$NAME.tar.gz"
    if [ -n "${TERMINA_APPIMAGE:-}" ]; then
      readonly TOOLS="$ROOT/build/deps/appimage"
      "$ROOT/tools/appimagetool.sh" "$TOOLS"
      readonly APPDIR="$OUT/Termina.AppDir"
      rm -rf "$APPDIR"
      cp -R "$STAGE" "$APPDIR"
      # The runtime runs AppRun; through the link the program is still at the AppDir's top,
      # so its `$ORIGIN/lib` finds the SDL3 beside it.
      ln -s termina "$APPDIR/AppRun"
      cp "$ROOT/assets/termina.desktop" "$ROOT/assets/termina.png" "$APPDIR/"
      ln -s termina.png "$APPDIR/.DirIcon"
      readonly IMAGE="$OUT/Termina-$VERSION-linux-$ARCH.AppImage"
      rm -f "$IMAGE"
      # Extracted and run, not mounted: a container or a CI runner has no FUSE.
      # appimagetool's ARCH is the machine's name for it (aarch64), through env: this
      # script's own ARCH is read-only.
      env APPIMAGE_EXTRACT_AND_RUN=1 ARCH="$(uname -m)" \
        "$TOOLS/appimagetool" --no-appstream --runtime-file "$TOOLS/runtime" "$APPDIR" "$IMAGE"
      rm -rf "$APPDIR"
      printf 'package: %s\n' "$IMAGE"
    fi
    rm -rf "$STAGE"
    ;;
  *) die "no packaging for $(uname -s)" ;;
esac
