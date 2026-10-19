# Sulafat — done

Finished work, moved from `todo.md` with its section; the rules it left behind are in
`CLAUDE.md`.

## The command line (M3)

- **[DONE 10/16] Tab completion** — zsh's own, captured by a widget and offered in a menu (`CLAUDE.md`, Tab completion).
- **[DONE 10/16] Filter the menu as you type** — typing narrows it from zsh's list and ⌫ widens it; it closes when nothing is left or the caret leaves the word.
- **[DONE 10/17] The command line pinned to the window's foot** — a box holding the prompt and the editor, as Warp has it; the menu opens upward.
- **[DONE 10/16] Type-ahead** — a `zle-line-init` hook reports keys waiting at a new line; a typed Return runs its line, the rest goes into the editor.
- **[DONE 10/19] bash's integration** — marks, commands, type-ahead and history through an `--rcfile` that reads what `bash -l` would; bash 4.4 or newer (`PS0`).

## Tabs

- **[DONE 10/16] Tabs** — a session each, read every frame; ⌘T/⌘W/⌘1–9/⌘⇧[ ⌘⇧], a `+` and close buttons, `•` for unseen output.
- **[DONE 10/16] Reorder tabs by dragging** — ImGui's bar, its order read back from where it draws each tab; the list, ⌘1–9 and the shown tab follow.
- **[DONE 10/16] Tabs in the Mac menu bar** — Shell ▸ New Tab, Show Previous/Next Tab, Close Tab; replaces SDL's bar, whose ⌘W closed the app.
- **[DONE 10/16] An Edit menu** — Undo, Redo, Cut, Copy, Paste, Select All; greyed when they would do nothing.
- **[DONE 10/16] Copy from the grid** — the grid's selection; Edit ▸ Copy takes it when the command line has none.
- **[DONE 10/19] A menu bar off macOS** — the Mac's menus drawn as ImGui's main menu bar, its choices the same tags; Settings… is in it.

## M1 — a classic terminal

- **[DONE 10/16] Colours and attributes** — SGR (both spellings) into styled cells, erases on the pen's background, drawn by runs.
- **[DONE 10/16] Bold as bright** — `Theme.bold_is_bright`, off by default; no setting to turn it on yet.
- **[DONE 10/16] Wide characters** — `vt/width.lyra`; a wide rune is a cell and a spacer; combining marks dropped.
- **[DONE 10/16] DEC private modes** — alternate screen (47/1047/1049), cursor keys, autowrap, keypad, DECSCUSR, mouse and focus modes.
- **[DONE 10/16] Mouse reporting** — 1000/1002/1003 in SGR or X10, wheel, modifiers; Shift selects; the wheel as arrows on the alternate screen.
- **[DONE 10/16] Selection and copy** — drag, double-click a word, triple-click a line, ⌘C; Select All while a program runs.
- **[DONE 10/16] Device reports** — DA1, DA2, XTVERSION, DSR, DECRQM and the colour queries answered.
- **[DONE 10/16] Alt as Meta off macOS** — Alt+key and Alt+Backspace as Escape-prefixed.
- **[DONE 10/19] Copying joins soft wraps** — a line the text went on from carries `WRAPPED` on its last cell; a copy joins it to the next.
- **[DONE 10/19] Glyphs for CJK and symbols** — fallback fonts merged into every face (`merge_font_file`, new in `bindings.imgui`); wide glyphs centred in their cells.
- **[DONE 10/19] Combining marks** — kept with the cell before them, in the screen's table, drawn and copied after its rune.
- **[DONE 10/19] Wide runes in the command line** — the editor's layout takes the grid's widths; a wide rune is drawn alone and wraps whole.

## Settings

- **[DONE 10/17] A settings window** — font family or file, size, line spacing, six themes, every colour, bold as bright; kept in `~/.config/sulafat/settings.json`.
