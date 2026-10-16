# Sulafat — open work

Open work for Sulafat only (compiler and binding gaps it finds go in `../lyra/todo.md`). The
milestones are in `CLAUDE.md` § Plan.

## The command line (M3)

- **[DONE 10/16] Tab completion** — zsh's own, captured by a widget and offered in a menu (`CLAUDE.md`, Tab completion).
- **[DONE 10/16] Filter the menu as you type** — typing narrows it from zsh's list and ⌫ widens it; it closes when nothing is left or the caret leaves the word.
- **[OPEN] Narrowing is literal** — a case-insensitive or substring `matcher-list` in the user's zsh shapes Tab's list, but typing then narrows by exact start; asking zsh again would honour it.
- **[OPEN] A completion's own suffix rules** — zsh removes an auto-added space or `/` when the next key is `/` or `)`; Sulafat keeps it.
- **[DONE 10/16] Type-ahead** — a `zle-line-init` hook reports keys waiting at a new line; a typed Return runs its line, the rest goes into the editor.
- **[OPEN] Right prompts** — zsh's `RPROMPT` sits under the editor's band and is hidden by nothing; text typed past it overlaps.
- **[OPEN] Syntax colouring, Ctrl+R search, bash integration** — next after Tab.

## Tabs

- **[DONE 10/16] Tabs** — a session each, read every frame; ⌘T/⌘W/⌘1–9/⌘⇧[ ⌘⇧], a `+` and close buttons, `•` for unseen output.
- **[OPEN] Reorder tabs by dragging** — ImGui can (`TAB_BAR_FLAGS_REORDERABLE`) but its order would part from ⌘1–9's; keep one order.
- **[DONE 10/16] Tabs in the Mac menu bar** — Shell ▸ New Tab, Show Previous/Next Tab, Close Tab; replaces SDL's bar, whose ⌘W closed the app.
- **[DONE 10/16] An Edit menu** — Undo, Redo, Cut, Copy, Paste, Select All; greyed when they would do nothing.
- **[OPEN] Copy from the grid** — Copy and Select All have nothing to act on while a program runs, until the grid has a selection (M1).

## M1 — a classic terminal

- **[DONE 10/16] Colours and attributes** — SGR (both spellings) into styled cells, erases on the pen's background, drawn by runs.
- **[OPEN] Bold as bright** — an option to draw bold 0–7 text in the bright colours, as old programs expect; off by default.
- **[OPEN] Wide characters** — an East Asian Width / emoji table; a wide rune takes two cells.
- **[OPEN] DEC private modes** — `?1049` alternate screen, `?1` cursor keys, `?2004` paste, `?25` cursor, `?7` autowrap.
- **[OPEN] Mouse reporting** — `?1000`/`?1002`/`?1006` (SGR) to the program; plain selection otherwise.
- **[OPEN] Selection and copy** — drag, double-click word, ⌘C.
- **[OPEN] Device reports** — `\e[c`, `\e[6n` and `\e[>c` answered; some programs wait for them.
- **[OPEN] Alt as Meta off macOS** — Alt+key sends `\e` then the key.

## Found along the way

- **[OPEN] Characters past the BMP arrive as U+FFFD** — `bindings.imgui` is built with 16-bit ImWchar; `IMGUI_USE_WCHAR32` would need the generator's `ImWchar` changed too.
- **[OPEN] Exit status** — a closed terminal comes before the program can be reaped; show the status once `exit_status()` answers.
