# Termina — done

Finished work, moved from `todo.md` with its section; the rules it left behind are in
`CLAUDE.md`.

## Blocks (M2)

- **[DONE 10/19] Blocks** — each command's input on the box's tint, its output plain; its duration, and a failure's status and red bar.
- **[DONE 10/19] The settings in a tab** — opened by Settings…, at the tab bar's right end, the whole area its own.
- **[DONE 10/19] Gruvbox Dark and Light** — among Termina's themes, in Gruvbox's own shades.
- **[DONE 10/19] Saved themes** — the colours under a name, in the Theme list after Termina's; replaced by saving again, deleted.
- **[DONE 10/19] Section, tab and command-line colours in the theme** — each theme's own, made from its colours where it does not name them; all in the settings window.
- **[DONE 10/19] Blocks as cards** — padding inside, a margin between; rows laid out by `Rows`, which everything that maps lines to heights asks.
- **[DONE 10/28] A block left open ends with the program's status** — the terminal closes as the program ends, a moment before it can be reaped; `Session.exit` keeps the status once `exit_status()` answers, and the block the program left open (its shell's `D` never coming) ends there, with the used rows as its end.
- **[DONE 10/29] Copying a block whole** — a right click on a block copies it: its command (past the prompt) on the input's lines, its output on the output's, a running block's output so far. `Block` now keeps where the command's text began (`cmd_line`/`cmd_col`, from the command line's send or the shell's `B` mark); `Session.block_copy_at` reads each part the way a selection over its lines would; `pointer_heard` returns a `CopyText` command for it.

## The command line (M3)

- **[DONE 10/16] Tab completion** — zsh's own, captured by a widget and offered in a menu (`CLAUDE.md`, Tab completion).
- **[DONE 10/16] Filter the menu as you type** — typing narrows it from zsh's list and ⌫ widens it; it closes when nothing is left or the caret leaves the word.
- **[DONE 10/17] The command line pinned to the window's foot** — a box holding the prompt and the editor, as Warp has it; the menu opens upward.
- **[DONE 10/16] Type-ahead** — a `zle-line-init` hook reports keys waiting at a new line; a typed Return runs its line, the rest goes into the editor.
- **[DONE 10/19] Narrowing honours the shell's matching** — typing asks the shell again; its answer is the menu as given.
- **[DONE 10/19] A completion's suffix gives way** — its `/` or space to a key that would double it or end the word.
- **[DONE 10/19] Prompts of several lines, and right prompts** — the box shows the prompt from its `A` mark, and `RPROMPT` right-aligned.
- **[DONE 10/19] bash runs a compspec's `-C` command** — as readline does.
- **[DONE 10/19] Syntax colouring** — commands, options, quoted text, variables, operators, comments, in the theme's colours.
- **[DONE 10/19] The box while a command runs** — kept, greyed, showing the command; the keys stay the program's.
- **[DONE 10/19] Ctrl+R history search** — the editor's text the query, the matches in a list above the box.
- **[DONE 10/19] bash's integration** — marks, commands, type-ahead and history through an `--rcfile` that reads what `bash -l` would; bash 4.4 or newer (`PS0`).
- **[DONE 10/19] bash's Tab completion** — a `bind -x` widget running what readline would (compspec, `-F` function, `compgen`), the word given unquoted; matches in the same menu as zsh's.

## Tabs

- **[DONE 10/16] Tabs** — a session each, read every frame; ⌘T/⌘W/⌘1–9/⌘⇧[ ⌘⇧], a `+` and close buttons, `•` for unseen output.
- **[DONE 10/16] Reorder tabs by dragging** — ImGui's bar, its order read back from where it draws each tab; the list, ⌘1–9 and the shown tab follow.
- **[DONE 10/16] Tabs in the Mac menu bar** — Shell ▸ New Tab, Show Previous/Next Tab, Close Tab; replaces SDL's bar, whose ⌘W closed the app.
- **[DONE 10/16] An Edit menu** — Undo, Redo, Cut, Copy, Paste, Select All; greyed when they would do nothing.
- **[DONE 10/16] Copy from the grid** — the grid's selection; Edit ▸ Copy takes it when the command line has none.
- **[DONE 10/19] The font's size from the keyboard** — View ▸ Bigger ⌘=, Smaller ⌘-, Default Font Size ⌘0 (Ctrl+Shift+= - 0 off macOS).
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
- **[DONE 10/19] Crisp text on Linux** — hinted through FreeType, built into `bindings.imgui` from a pinned download; macOS unchanged.
- **[DONE 10/19] Combining marks** — kept with the cell before them, in the screen's table, drawn and copied after its rune.
- **[DONE 10/19] Wide runes in the command line** — the editor's layout takes the grid's widths; a wide rune is drawn alone and wraps whole.
- **[DONE 10/28] The filler before a wrapped wide rune is not copied** — the blank the screen leaves where a wide rune wrapped early is `FILLER` (style), and a copy joining the wrapped line drops it alone; the line's own trailing blanks are kept.

## Settings

- **[DONE 10/17] A settings window** — font family or file, size, line spacing, six themes, every colour, bold as bright; kept in `~/.config/termina/settings.json`.

## The window on `ui` (10/23)

- **[DONE 10/23] Termina on lyra's `ui`** — the tab bar, the menus (the Mac's own bar, a header bar's ☰ elsewhere), the Settings tab in markup, a see-through background; the Dear ImGui front end, uitest and menutest gone (lyra's `ui/WINDOW.md` step 9).
- **[DONE 10/26] The tab bar's underline's color and thickness** — Tabs ▸ Underline, the thickness in its picker.
- **[DONE 10/26] Each background blurred on its own** — the window's, the input's and the output's, each by a slider in its colour's picker; a section frosts the desktop behind it (macOS).
- **[DONE 10/26] A Save button for an edited saved theme; the hex in the pickers copied and pasted; each font family listed in itself.**
- **[DONE 10/26] Translucent sections** — the input and output colours take an opacity, as the background's does; a translucent command line box shows the transcript scrolled under it, blurred (Settings ▸ Window, macOS); the transcript clipped at the box rather than covered, so nothing shows behind its rounded corners; the Settings controls on a panel of the output's colour.
- **[DONE 10/23] Characters past the BMP** — arrived as U+FFFD through ImGui's 16-bit `ImWchar`; `ui` takes typed text as UTF-8.
