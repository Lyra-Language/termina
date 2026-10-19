# Sulafat — open work

Open work for Sulafat only (compiler and binding gaps it finds go in `../lyra/todo.md`). The
milestones are in `CLAUDE.md` § Plan; finished items move to `done.md`.

## The command line (M3)

- **[OPEN] Narrowing is literal** — a case-insensitive or substring `matcher-list` in the user's zsh shapes Tab's list, but typing then narrows by exact start; asking zsh again would honour it.
- **[OPEN] A completion's own suffix rules** — zsh removes an auto-added space or `/` when the next key is `/` or `)`; Sulafat keeps it.
- **[OPEN] Right prompts and two-line prompts** — the box shows the prompt's last line before the input column; an `RPROMPT`, or a prompt's earlier lines, stay in the transcript above.
- **[OPEN] The box while a command runs** — it goes; Warp keeps it, greyed, to type the next command in.
- **[OPEN] Syntax colouring, Ctrl+R search, bash integration** — next after Tab.

## Tabs


## M1 — a classic terminal

- **[OPEN] Colour emoji** — CJK and symbols come from fallback fonts, but emoji need ImGui's FreeType loader with colour, and `IMGUI_USE_WCHAR32` (below) to reach them at all.
- **[OPEN] Copies keep the filler before a wrapped wide rune** — a wide rune that wrapped early leaves a blank in the last column, which a joined copy includes as a space.

## Settings

- **[OPEN] The command line's own colours** — its band, completion menu and chosen row are fixed; they could follow the theme.
- **[OPEN] Settings window on Linux needs a way in besides Ctrl+,** — there is no menu bar to show it.

## Found along the way

- **[OPEN] Characters past the BMP arrive as U+FFFD** — `bindings.imgui` is built with 16-bit ImWchar; `IMGUI_USE_WCHAR32` would need the generator's `ImWchar` changed too.
- **[OPEN] Exit status** — a closed terminal comes before the program can be reaped; show the status once `exit_status()` answers.
