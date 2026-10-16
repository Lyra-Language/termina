# Sulafat

A terminal written in [Lyra](https://github.com/Lyra-Language/lyra), after Warp: commands
and their output as blocks, and a command line you edit like text in an editor. macOS and
Linux.

**Status: M0.** The login shell runs in a window, and you can type to it, paste into it and
scroll back. Text is monochrome so far; colours, full-screen programs, blocks and the editor
come next (`CLAUDE.md` § Plan).

```bash
../lyra/build.sh     # the compiler, with std/ and bindings/ beside it (SDL3 needed)
./build.sh           # build/sulafat and build/vttest
build/sulafat
```

MIT licensed (`LICENSE`).
