#!/usr/bin/env bash
#
# Build SDL3 from its release source for a Termina release: a shared library and its
# pkg-config file under <prefix>, for lyra's build (bindings/imgui) and Termina's to build
# against, and package.sh to put beside the program.
#
#   tools/sdl3.sh <prefix>       # -> <prefix>/lib/libSDL3.{0.dylib,so.0}, lib/pkgconfig/sdl3.pc
#
# **Not the system's SDL3**: Homebrew's is built for the macOS it runs on and lives at a
# Homebrew path, and Ubuntu 24.04 has none. Built here, it is the same SDL3 on every
# platform, and on a Mac it runs back to $MACOSX_DEPLOYMENT_TARGET (the release workflow
# sets it).
#
# **The pin is lyra's** (`lyra/tools/sdl3-ios.sh`, the release `bindings.sdl3` is written
# against): move SDL_VERSION and SDL_SHA256 there and here together. A download that is
# not byte for byte the pinned one is refused.
#
# **Found where it was installed**: a Mac's library is named by its full path (as
# Homebrew's is), and on Linux the release workflow sets LD_LIBRARY_PATH — so the checks
# run the programs as built; package.sh then points them at the copy they carry.
#
# On Linux, SDL finds X11, Wayland and the rest at run time but needs their headers here
# to build in support for them; the release workflow installs them (README-linux.md in
# SDL's docs lists them). Needs curl, tar, cmake and ninja.
set -euo pipefail

readonly SDL_VERSION="3.4.18"
readonly SDL_SHA256="9c75cf16330322c217dedd2e0609f1124f1b54b8633e763467b4684d0f4334a3"

readonly PREFIX="$(mkdir -p "${1:?usage: tools/sdl3.sh <prefix>}" && cd "$1" && pwd)"
readonly WORK="$PREFIX/src"

die() { printf 'tools/sdl3: %s\n' "$*" >&2; exit 1; }

for tool in curl tar cmake ninja; do
  command -v "$tool" >/dev/null 2>&1 || die "$tool not found"
done

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1"; else shasum -a 256 "$1"; fi |
    cut -d' ' -f1
}

readonly TARBALL="$WORK/SDL3-$SDL_VERSION.tar.gz"
mkdir -p "$WORK"
if [ ! -f "$TARBALL" ] || [ "$(sha256 "$TARBALL")" != "$SDL_SHA256" ]; then
  curl -fsSL --retry 2 -o "$TARBALL.part" \
    "https://github.com/libsdl-org/SDL/releases/download/release-$SDL_VERSION/SDL3-$SDL_VERSION.tar.gz" ||
    { rm -f "$TARBALL.part"; die "download failed"; }
  got="$(sha256 "$TARBALL.part")"
  [ "$got" = "$SDL_SHA256" ] || { rm -f "$TARBALL.part"; die "checksum mismatch (got $got)"; }
  mv "$TARBALL.part" "$TARBALL"
fi
tar -xzf "$TARBALL" -C "$WORK"

cmake -S "$WORK/SDL3-$SDL_VERSION" -B "$WORK/build" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_INSTALL_NAME_DIR="$PREFIX/lib" \
  -DSDL_SHARED=ON -DSDL_STATIC=OFF \
  -DSDL_TESTS=OFF -DSDL_EXAMPLES=OFF
cmake --build "$WORK/build"
cmake --install "$WORK/build"
printf 'tools/sdl3: SDL3 %s in %s\n' "$SDL_VERSION" "$PREFIX"
