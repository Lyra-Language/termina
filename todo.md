# Sulafat — open work

Open work for Sulafat only (compiler and binding gaps it finds go in `../lyra/todo.md`). The
milestones are in `CLAUDE.md` § Plan; finished items move to `done.md`.

## The command line (M3)

- **[OPEN] Narrowing is literal** — a case-insensitive or substring `matcher-list` in the user's zsh shapes Tab's list, but typing then narrows by exact start; asking zsh again would honour it.
- **[OPEN] A completion's own suffix rules** — zsh removes an auto-added space or `/` when the next key is `/` or `)`; Sulafat keeps it.
- **[OPEN] Right prompts** — zsh's `RPROMPT` sits under the editor's band and is hidden by nothing; text typed past it overlaps.
- **[OPEN] Syntax colouring, Ctrl+R search, bash integration** — next after Tab.

## Tabs


## M1 — a classic terminal

- **[OPEN] Copying keeps soft wraps as line breaks** — the screen does not record which lines wrapped, so a long line copies as several.
- **[OPEN] Glyphs for CJK and emoji** — wide runes take their two cells, but SF Mono has no CJK glyphs and stb_truetype no colour emoji; a fallback font is needed.
- **[OPEN] Combining marks** — dropped; a cell would need a rune and its marks.
- **[OPEN] Wide runes in the command line** — the editor lays out a rune a column.
- **[OPEN] A setting for bold as bright** — the theme has it; nothing turns it on.

## Found along the way

- **[OPEN] Characters past the BMP arrive as U+FFFD** — `bindings.imgui` is built with 16-bit ImWchar; `IMGUI_USE_WCHAR32` would need the generator's `ImWchar` changed too.
- **[OPEN] Exit status** — a closed terminal comes before the program can be reaped; show the status once `exit_status()` answers.
