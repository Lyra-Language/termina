<img src="assets/termina.png" alt="Termina's icon" width="128" align="right">

# Termina

A terminal written in [Lyra](https://github.com/Lyra-Language/lyra), after Warp: commands
and their output as blocks, and a command line you edit like text in an editor. macOS and
Linux.

**Status: early.** The login shell runs in a window, in tabs (⌘T, ⌘W, ⌘1–9). With zsh or bash (4.4 or newer), the command line is an
editor of Termina's own, in a box pinned to the window's foot: several lines, the mouse (double-click a word to select it),
word-by-word motions, undo, the clipboard, history, and Tab completion — the shell's own, in a menu. It is a classic terminal underneath: color (16, 256,
24-bit) and attributes, wide characters, full-screen programs (vim, less, top), the mouse, and
selection and copy. Termina ▸ Settings… (⌘,) chooses the font, its size, the colors — a
see-through background, blurred behind on a Mac — and whether the window reopens where it
was. It is drawn with Lyra's own GUI framework (`ui`). Blocks come next (`CLAUDE.md` § Plan).

```bash
../lyra/build.sh     # the compiler, with std/, bindings/ and ui/ beside it (SDL3, FreeType
                     #   and HarfBuzz needed)
./build.sh           # build/termina (and build/Termina.app on macOS), and vttest
build/termina
tools/check.sh       # the window played headless, its checks
```

Releases (`git tag vX.Y.Z` and push it) carry Termina.app for Apple silicon, signed with a
Developer ID and notarized, and for Linux on x86_64 and arm64 an AppImage (make it
executable and run it once: it adds itself to your desktop's launcher) and an archive
(unpack and run `./termina`). Each has SDL3 inside, and FreeType and HarfBuzz built in.

MIT licensed (`LICENSE`).
