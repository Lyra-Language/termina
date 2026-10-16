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

## M1 — a classic terminal

- **[DONE 10/16] Colours and attributes** — SGR (both spellings) into styled cells, erases on the pen's background, drawn by runs.
