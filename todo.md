# Sulafat — open work

Open work for Sulafat only (compiler and binding gaps it finds go in `../lyra/todo.md`). The
milestones are in `CLAUDE.md` § Plan.

## M1 — a classic terminal

- **[OPEN] Colours and attributes** — SGR into a cell (rune, fg, bg, flags); draw runs of one style.
- **[OPEN] Wide characters** — an East Asian Width / emoji table; a wide rune takes two cells.
- **[OPEN] DEC private modes** — `?1049` alternate screen, `?1` cursor keys, `?2004` paste, `?25` cursor, `?7` autowrap.
- **[OPEN] Mouse reporting** — `?1000`/`?1002`/`?1006` (SGR) to the program; plain selection otherwise.
- **[OPEN] Selection and copy** — drag, double-click word, ⌘C.
- **[OPEN] Device reports** — `\e[c`, `\e[6n` and `\e[>c` answered; some programs wait for them.
- **[OPEN] Alt as Meta off macOS** — Alt+key sends `\e` then the key.

## Found along the way

- **[OPEN] Characters past the BMP arrive as U+FFFD** — `bindings.imgui` is built with 16-bit ImWchar; `IMGUI_USE_WCHAR32` would need the generator's `ImWchar` changed too.
- **[OPEN] Exit status** — a closed terminal comes before the program can be reaped; show the status once `exit_status()` answers.
