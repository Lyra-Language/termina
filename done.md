# Sulafat — done

Finished work, moved from `todo.md` with its section; the rules it left behind are in
`CLAUDE.md`.

## The command line (M3)

- **[DONE 10/16] Tab completion** — zsh's own, captured by a widget and offered in a menu (`CLAUDE.md`, Tab completion).
- **[DONE 10/16] Filter the menu as you type** — typing narrows it from zsh's list and ⌫ widens it; it closes when nothing is left or the caret leaves the word.
- **[DONE 10/16] Type-ahead** — a `zle-line-init` hook reports keys waiting at a new line; a typed Return runs its line, the rest goes into the editor.

## Tabs

- **[DONE 10/16] Tabs** — a session each, read every frame; ⌘T/⌘W/⌘1–9/⌘⇧[ ⌘⇧], a `+` and close buttons, `•` for unseen output.
- **[DONE 10/16] Reorder tabs by dragging** — ImGui's bar, its order read back from where it draws each tab; the list, ⌘1–9 and the shown tab follow.
- **[DONE 10/16] Tabs in the Mac menu bar** — Shell ▸ New Tab, Show Previous/Next Tab, Close Tab; replaces SDL's bar, whose ⌘W closed the app.
- **[DONE 10/16] An Edit menu** — Undo, Redo, Cut, Copy, Paste, Select All; greyed when they would do nothing.
- **[DONE 10/16] Copy from the grid** — the grid's selection; Edit ▸ Copy takes it when the command line has none.

## M1 — a classic terminal

- **[DONE 10/16] Colours and attributes** — SGR (both spellings) into styled cells, erases on the pen's background, drawn by runs.
- **[DONE 10/16] Bold as bright** — `Theme.bold_is_bright`, off by default; no setting to turn it on yet.
- **[DONE 10/16] Wide characters** — `vt/width.lyra`; a wide rune is a cell and a spacer; combining marks dropped.
- **[DONE 10/16] DEC private modes** — alternate screen (47/1047/1049), cursor keys, autowrap, keypad, DECSCUSR, mouse and focus modes.
- **[DONE 10/16] Mouse reporting** — 1000/1002/1003 in SGR or X10, wheel, modifiers; Shift selects; the wheel as arrows on the alternate screen.
- **[DONE 10/16] Selection and copy** — drag, double-click a word, triple-click a line, ⌘C; Select All while a program runs.
- **[DONE 10/16] Device reports** — DA1, DA2, XTVERSION, DSR, DECRQM and the colour queries answered.
- **[DONE 10/16] Alt as Meta off macOS** — Alt+key and Alt+Backspace as Escape-prefixed.
