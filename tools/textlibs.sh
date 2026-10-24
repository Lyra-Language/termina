#!/usr/bin/env bash
#
# Build FreeType and HarfBuzz from their release sources for a Termina release: static
# libraries and their pkg-config files under <prefix>, which lyra's `bindings.freetype` and
# `bindings.harfbuzz` (`@link(…, pkg: …)`) find through PKG_CONFIG_PATH, so the program carries
# them and needs neither installed.
#
#   tools/textlibs.sh <prefix>   # -> <prefix>/lib/lib{freetype,harfbuzz}.a,
#                                #    lib/pkgconfig/{freetype2,harfbuzz}.pc, include/
#
# **Not the system's**: Homebrew's are shared libraries built for the macOS they run on, at a
# Homebrew path, and a Linux desktop's are whatever version it has. Static, they are inside the
# program. **Nothing optional**: no zlib, bzip2, PNG or Brotli for FreeType (a font is read as
# it is), no GLib, ICU or Graphite for HarfBuzz — so nothing more to carry.
#
# **HarfBuzz is its one amalgamated source** (`src/harfbuzz.cc`), compiled without C++
# exceptions, RTTI or thread-safe statics, as HarfBuzz's own build does: it then needs no C++
# runtime, and links into a C program as a C library would.
#
# FreeType's pin is lyra's (`bindings/imgui/build.sh`); HarfBuzz's SHA-256 is of the release's
# tarball as downloaded 10/23/26. A download that is not byte for byte the pinned one is
# refused. On a Mac the libraries run back to $MACOSX_DEPLOYMENT_TARGET (the release workflow
# sets it). Needs curl, a tar that reads .tar.xz (macOS's does itself; GNU tar with xz),
# cmake, ninja and a C and C++ compiler.
set -euo pipefail

readonly FREETYPE_VERSION="2.13.3"
readonly FREETYPE_SHA256="5c3a8e78f7b24c20b25b54ee575d6daa40007a5f4eea2845861c3409b3021747"
readonly HARFBUZZ_VERSION="11.2.1"
readonly HARFBUZZ_SHA256="093714c8548a285094685f0bdc999e202d666b59eeb3df2ff921ab68b8336a49"

readonly PREFIX="$(mkdir -p "${1:?usage: tools/textlibs.sh <prefix>}" && cd "$1" && pwd)"
readonly WORK="$PREFIX/src"
readonly CC="${CC:-cc}"
readonly CXX="${CXX:-c++}"

die() { printf 'tools/textlibs: %s\n' "$*" >&2; exit 1; }

for tool in curl tar cmake ninja; do
  command -v "$tool" >/dev/null 2>&1 || die "$tool not found"
done

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1"; else shasum -a 256 "$1"; fi |
    cut -d' ' -f1
}

# fetch <url> <dest> <sha256>: download to <dest> unless it is already there, checked.
fetch() {
  if [ -f "$2" ] && [ "$(sha256 "$2")" = "$3" ]; then return; fi
  curl -fsSL --retry 2 -o "$2.part" "$1" || { rm -f "$2.part"; die "download of $1 failed"; }
  got="$(sha256 "$2.part")"
  [ "$got" = "$3" ] || { rm -f "$2.part"; die "checksum mismatch for $1 (got $got)"; }
  mv "$2.part" "$2"
}

mkdir -p "$WORK" "$PREFIX/lib/pkgconfig" "$PREFIX/include/harfbuzz"

# ── FreeType ─────────────────────────────────────────────────────────────────

fetch "https://download.savannah.gnu.org/releases/freetype/freetype-$FREETYPE_VERSION.tar.gz" \
  "$WORK/freetype-$FREETYPE_VERSION.tar.gz" "$FREETYPE_SHA256"
tar -xzf "$WORK/freetype-$FREETYPE_VERSION.tar.gz" -C "$WORK"
cmake -S "$WORK/freetype-$FREETYPE_VERSION" -B "$WORK/freetype-build" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DBUILD_SHARED_LIBS=OFF \
  -DFT_DISABLE_ZLIB=ON \
  -DFT_DISABLE_BZIP2=ON \
  -DFT_DISABLE_PNG=ON \
  -DFT_DISABLE_HARFBUZZ=ON \
  -DFT_DISABLE_BROTLI=ON
cmake --build "$WORK/freetype-build"
cmake --install "$WORK/freetype-build"

# ── HarfBuzz ─────────────────────────────────────────────────────────────────

fetch "https://github.com/harfbuzz/harfbuzz/releases/download/$HARFBUZZ_VERSION/harfbuzz-$HARFBUZZ_VERSION.tar.xz" \
  "$WORK/harfbuzz-$HARFBUZZ_VERSION.tar.xz" "$HARFBUZZ_SHA256"
tar -xJf "$WORK/harfbuzz-$HARFBUZZ_VERSION.tar.xz" -C "$WORK"
readonly HB="$WORK/harfbuzz-$HARFBUZZ_VERSION/src"
# FreeType's functions HarfBuzz's hb-ft asks for by feature macro: all in this FreeType. And
# HAVE_PTHREAD, which only a Mac implies: without it HarfBuzz's lock is std::mutex, whose
# libstdc++ `lock` throws — the one thing that needed the C++ runtime on Linux.
"$CXX" -O2 -fPIC -std=c++11 -fno-exceptions -fno-rtti -fno-threadsafe-statics \
  -DHAVE_PTHREAD=1 -DHAVE_FREETYPE=1 -DHAVE_FT_GET_VAR_BLEND_COORDINATES=1 -DHAVE_FT_SET_VAR_BLEND_COORDINATES=1 \
  -DHAVE_FT_DONE_MM_VAR=1 -DHAVE_FT_GET_TRANSFORM=1 \
  -I"$PREFIX/include/freetype2" -c "$HB/harfbuzz.cc" -o "$WORK/harfbuzz.o"
# Refused here rather than at the program's link: a C program links no C++ runtime.
if nm -u "$WORK/harfbuzz.o" | grep -E '_ZNSt|_ZSt|__cxa|__gxx|_Znw|_Zna|_ZdlPv|_ZdaPv' >&2; then
  die "HarfBuzz needs the C++ runtime for the symbols above"
fi
rm -f "$PREFIX/lib/libharfbuzz.a"
ar rcs "$PREFIX/lib/libharfbuzz.a" "$WORK/harfbuzz.o"
cp "$HB"/hb.h "$HB"/hb-*.h "$PREFIX/include/harfbuzz/"
cat > "$PREFIX/lib/pkgconfig/harfbuzz.pc" <<PC
prefix=$PREFIX
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: harfbuzz
Description: HarfBuzz text shaping library, static, built for Termina
Version: $HARFBUZZ_VERSION
Requires: freetype2
Libs: -L\${libdir} -lharfbuzz
Libs.private: -lm
Cflags: -I\${includedir}/harfbuzz
PC

# Static only: a shared library left here would be what the linker takes.
for lib in "$PREFIX"/lib/*.dylib "$PREFIX"/lib/*.so*; do
  [ -e "$lib" ] && die "a shared library was built: $lib"
done
printf 'tools/textlibs: FreeType %s and HarfBuzz %s in %s\n' "$FREETYPE_VERSION" "$HARFBUZZ_VERSION" "$PREFIX"
