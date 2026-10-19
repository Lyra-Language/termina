<img src="assets/termina.png" alt="Termina's icon" width="128" align="right">

# Termina

A terminal written in [Lyra](https://github.com/Lyra-Language/lyra), after Warp: commands
and their output as blocks, and a command line you edit like text in an editor. macOS and
Linux.

**Status: early.** The login shell runs in a window, in tabs (⌘T, ⌘W, ⌘1–9). With zsh or bash (4.4 or newer), the command line is an
editor of Termina's own, in a box pinned to the window's foot: several lines, the mouse (double-click a word to select it),
word-by-word motions, undo, the clipboard, history, and Tab completion — the shell's own, in a menu. It is a classic terminal underneath: colour (16, 256,
24-bit) and attributes, wide characters, full-screen programs (vim, less, top), the mouse, and
selection and copy. Termina ▸ Settings… (⌘,) chooses the font, its size and the colours. Blocks
come next (`CLAUDE.md` § Plan).

```bash
../lyra/build.sh     # the compiler, with std/ and bindings/ beside it (SDL3 needed)
./build.sh           # build/termina (and build/Termina.app on macOS), and the tests
build/termina
```

Releases (`git tag vX.Y.Z` and push it) carry Termina.app for Apple silicon, signed ad hoc
— open it the first time with right-click ▸ Open — and archives for Linux on x86_64 and
arm64: unpack and run `./termina`. Each has SDL3 inside.

MIT licensed (`LICENSE`).
