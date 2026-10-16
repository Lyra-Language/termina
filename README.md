# Sulafat

A terminal written in [Lyra](https://github.com/Lyra-Language/lyra), after Warp: commands
and their output as blocks, and a command line you edit like text in an editor. macOS and
Linux.

**Status: early.** The login shell runs in a window, in tabs (⌘T, ⌘W, ⌘1–9). With zsh, the command line is an
editor of Sulafat's own: several lines, the mouse (double-click a word to select it),
word-by-word motions, undo, the clipboard, history, and Tab completion — zsh's own, in a menu. Text is in colour, 16, 256 and 24-bit, with
bold, italic, underlines, strikethrough and inverse. Full-screen programs and blocks come next (`CLAUDE.md` § Plan).

```bash
../lyra/build.sh     # the compiler, with std/ and bindings/ beside it (SDL3 needed)
./build.sh           # build/sulafat (and build/Sulafat.app on macOS), and the tests
build/sulafat
```

MIT licensed (`LICENSE`).
