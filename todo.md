# Termina — open work

Open work for Termina only (compiler and binding gaps it finds go in `../lyra/todo.md`). The
milestones are in `CLAUDE.md` § Plan; finished items move to `done.md`.

## Blocks (M2)

- **[OPEN] A block whole** — select, copy (command or output) and fold one, as Warp does.

## The command line (M3)

- **[OPEN] A command that does not exist** — syntax coloring could show it red, but Termina cannot see the shell's aliases and functions; asking the shell (`type`) per command word would.

## M1 — a classic terminal

- **[OPEN] Color emoji** — CJK and symbols come from fallback fonts, but emoji need ImGui's FreeType loader with color, and `IMGUI_USE_WCHAR32` (below) to reach them at all.
- **[OPEN] Copies keep the filler before a wrapped wide rune** — a wide rune that wrapped early leaves a blank in the last column, which a joined copy includes as a space.

## Settings

## Found along the way

- **[OPEN] Characters past the BMP arrive as U+FFFD** — `bindings.imgui` is built with 16-bit ImWchar; `IMGUI_USE_WCHAR32` would need the generator's `ImWchar` changed too.
- **[OPEN] Exit status** — a closed terminal comes before the program can be reaped; show the status once `exit_status()` answers.
