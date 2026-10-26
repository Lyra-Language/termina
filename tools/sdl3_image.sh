#!/usr/bin/env bash
#
# Build SDL3_image from its release source for a Termina release: a static library and its
# pkg-config file under <prefix>, which lyra's `bindings.sdl3_image` (`@link(…, pkg:
# "sdl3-image")`) finds through PKG_CONFIG_PATH, so the program carries it and needs none
# installed. Built against the SDL3 pkg-config finds (`tools/sdl3.sh`'s, in a release).
#
#   tools/sdl3_image.sh <prefix>   # -> <prefix>/lib/libSDL3_image.a, lib/pkgconfig/sdl3-image.pc
#
# **Its own decoders only**: stb_image for PNG and JPEG, nanosvg for SVG, and the other formats
# it decodes with no library (BMP, GIF, QOI, TGA, …) — no libpng, libavif, libwebp, libjxl or
# libtiff, and not a Mac's ImageIO, so it decodes the same on every platform and the program
# carries nothing more. Saving images is left out: Termina only reads them.
#
# The SHA-256 is of the release's tarball as downloaded 10/26/26; a download that is not byte
# for byte the pinned one is refused. On a Mac it runs back to $MACOSX_DEPLOYMENT_TARGET (the
# release workflow sets it). Needs curl, tar, cmake, ninja, pkg-config and a C compiler.
set -euo pipefail

readonly IMAGE_VERSION="3.4.8"
readonly IMAGE_SHA256="e8223b424bc7541cf84ffff5cf7e4f24ec3711c60462cb1bd6dc1d7bd7f25477"

readonly PREFIX="$(mkdir -p "${1:?usage: tools/sdl3_image.sh <prefix>}" && cd "$1" && pwd)"
readonly WORK="$PREFIX/src"

die() { printf 'tools/sdl3_image: %s\n' "$*" >&2; exit 1; }

for tool in curl tar cmake ninja pkg-config; do
  command -v "$tool" >/dev/null 2>&1 || die "$tool not found"
done
SDL_PREFIX="$(pkg-config --variable=prefix sdl3)" || die "SDL3 not found by pkg-config"
readonly SDL_PREFIX

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1"; else shasum -a 256 "$1"; fi |
    cut -d' ' -f1
}

readonly TARBALL="$WORK/SDL3_image-$IMAGE_VERSION.tar.gz"
mkdir -p "$WORK"
if [ ! -f "$TARBALL" ] || [ "$(sha256 "$TARBALL")" != "$IMAGE_SHA256" ]; then
  curl -fsSL --retry 2 -o "$TARBALL.part" \
    "https://github.com/libsdl-org/SDL_image/releases/download/release-$IMAGE_VERSION/SDL3_image-$IMAGE_VERSION.tar.gz" ||
    { rm -f "$TARBALL.part"; die "download failed"; }
  got="$(sha256 "$TARBALL.part")"
  [ "$got" = "$IMAGE_SHA256" ] || { rm -f "$TARBALL.part"; die "checksum mismatch (got $got)"; }
  mv "$TARBALL.part" "$TARBALL"
fi
tar -xzf "$TARBALL" -C "$WORK"

cmake -S "$WORK/SDL3_image-$IMAGE_VERSION" -B "$WORK/build" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_PREFIX_PATH="$SDL_PREFIX" \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DBUILD_SHARED_LIBS=OFF \
  -DSDLIMAGE_VENDORED=OFF \
  -DSDLIMAGE_SAMPLES=OFF \
  -DSDLIMAGE_TESTS=OFF \
  -DSDLIMAGE_BACKEND_STB=ON \
  -DSDLIMAGE_BACKEND_IMAGEIO=OFF \
  -DSDLIMAGE_PNG_LIBPNG=OFF \
  -DSDLIMAGE_AVIF=OFF \
  -DSDLIMAGE_JXL=OFF \
  -DSDLIMAGE_TIF=OFF \
  -DSDLIMAGE_WEBP=OFF \
  -DSDLIMAGE_ANI_SAVE=OFF \
  -DSDLIMAGE_BMP_SAVE=OFF \
  -DSDLIMAGE_GIF_SAVE=OFF \
  -DSDLIMAGE_JPG_SAVE=OFF \
  -DSDLIMAGE_PNG_SAVE=OFF \
  -DSDLIMAGE_TGA_SAVE=OFF
cmake --build "$WORK/build"
cmake --install "$WORK/build"

# Static only: a shared library left here would be what the linker takes.
for lib in "$PREFIX"/lib/*.dylib "$PREFIX"/lib/*.so*; do
  [ -e "$lib" ] && die "a shared library was built: $lib"
done
[ -f "$PREFIX/lib/pkgconfig/sdl3-image.pc" ] || die "no sdl3-image.pc was installed"
printf 'tools/sdl3_image: SDL3_image %s in %s\n' "$IMAGE_VERSION" "$PREFIX"
