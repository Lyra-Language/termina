# Sulafat — Project Context

Sulafat (γ Lyrae) is a terminal emulator written in Lyra, after Warp: commands and their
output as **blocks**, and a command line that edits like a text editor rather than a shell's
line editor. **Open source, MIT** (`LICENSE`); the repository is private until published, and
contributions are not being accepted yet. Lives in the Lyra workspace beside `lyra/`; the
workspace's `CLAUDE.md` rules apply here too. **macOS and Linux** — Windows waits on Lyra
(`pkg/abi` has no Windows convention, `std.io` is POSIX, and Windows' PTY is ConPTY).

## Commands

```bash
../lyra/build.sh            # the compiler, std/, bindings/ and lib/liblyra-{pty,imgui}.a
./build.sh                  # -> build/: sulafat (and Sulafat.app on macOS), vttest, uitest
build/sulafat               # the login shell ($SHELL -l) in a window of tabs: ⌘T new (in the
                            #    shown tab's directory), ⌘W close, ⌘1–⌘9, ⌘⇧[ ⌘⇧]; a tab
                            #    closes when its shell ends, the window with the last
build/sulafat CMD [ARG…]    # that program instead (as xterm -e), no integration — a test
                            #    script's colours, say, seen without typing
open build/Sulafat.app      # the same, as a Mac app
                            # Settings… (⌘,; Ctrl+, off macOS): font, size, spacing, colours —
                            #    kept in ~/.config/sulafat/settings.json ($XDG_CONFIG_HOME)
build/vttest                # parser, screen, editor, PTY, zsh and bash checks; exit 1 on a failure
SDL_VIDEODRIVER=dummy build/uitest   # the command line on a headless ImGui host, driven by
                            #    injected keys, typing and clicks (double-click included)
build/menutest              # the Mac's menu bar, installed and read back (SDL's real video
                            #    driver, no window)
```

## Architecture

```
shell ⇄ bindings.pty ──bytes──▶ vt.Parser ──[]Action──▶ vt.Screen ──▶ draw (ImGui DrawList)
  ▲                                                       │ marks (OSC 133)
  │                                                       ▼
  ├──── keys as typed (send_keys) ◀──────── Mode: Raw ─┬─ AtPrompt(line, col)
  └──── submission (bracketed paste + ⏎) ◀── ui.CommandLine ◀─ editor.Editor
```

| file | what |
|---|---|
| `src/sulafat.lyra` | `main`: the ImGui host, the frame loop, the tabs and their bar, fonts |
| `src/session/session.lyra` | one tab: its PTY, screen, `Mode` and command line; read each frame, drawn and given keys when shown |
| `src/ui/tabs.lyra` | the tab bar (reorderable, its order read back), the tab shortcuts, and the Mac's menu bar |
| `src/ui/menu_bar.lyra` | the menu bar Sulafat draws off macOS: the Mac's menus as ImGui's main menu bar |
| `src/menutest.lyra` | the menu bar installed and read back |
| `src/shell/shell.lyra` | shell integration (zsh's `.zshenv` through `ZDOTDIR`, bash's rc file through `--rcfile`): the marks, Tab's completion widget and its request file, the history files, what Return sends |
| `src/editor/editor.lyra` | the command line's editor — text, caret, selection, motions, words, undo, layout; **pure** |
| `src/ui/modifiers.lyra` | the modifier keys as pressed — ImGui's macOS Ctrl/⌘ swap undone |
| `src/ui/typeahead.lyra` | keys typed ahead, raw, made into lines (Backspace, Ctrl+U/W applied; escapes dropped) |
| `src/ui/command_line.lyra` | the editor at the prompt: keys and mouse into editor calls, history, the completion menu, drawing |
| `src/vt/parser.lyra` | bytes → `Action`s — Paul Williams' DEC parser; **pure**, keeps all state across reads |
| `src/vt/screen.lyra` | `Action`s → the cell grid, cursor, scroll region, scrollback ring |
| `src/vt/width.lyra` | how many cells a rune takes: 2 wide (CJK, emoji), 0 combining, 1 the rest |
| `src/vt/selection.lyra` | a selection on the screen and scrollback: its text, a word's span; **pure** |
| `src/vt/style.lyra` | a `Cell`'s colours and attributes, and SGR on the `Pen` that writes them; **pure** |
| `src/settings/settings.lyra` | the user's settings, the themes offered, the file (read leniently), the monospaced families found |
| `src/ui/settings_window.lyra` | the settings window: font family or file, size, spacing, theme, every colour, bold as bright |
| `src/ui/theme.lyra` | recorded colours → pixels: the theme's own pair, ANSI 16, xterm's 256; inverse, dim, hidden |
| `src/ui/grid.lyra` | a screen line drawn: background runs, text runs of one style, faces, underlines, strike |
| `src/vttest.lyra` | the checks: byte strings against actions and screens, the editor on text, real programs, zsh and bash on a PTY (each skipped, and said so, where not installed) |
| `src/uitest.lyra` | the command line on a headless host: injected input, the editor checked after |

- **The parser recognises, the screen acts.** Neither reads the other's input: the parser is
  tested on bytes alone, the screen on actions. A new sequence is a `Screen.csi`/`esc`/`osc`
  case and a `vttest` line.
- **Every tab is read every frame, shown or not** (`Session.step`), so a program writing in a
  hidden tab never waits on a full terminal; only the shown one is drawn and gets keys.
  **Reading only ever ends a tab** (`alive` cleared, never set): a tab the user closed
  (`request_close`) stays closed though its program has not ended yet. **Tabs drag into a new order** (`TAB_BAR_FLAGS_REORDERABLE`): ImGui keeps that order to
  itself, so `ui.tab_bar` reads each tab's place after drawing it and answers the order
  (`TabBar.order`), and the loop puts its sessions in it — one order for the bar, ⌘1–9 and
  ⌘⇧[ ⌘⇧], the shown tab followed. A
  tab's label is `name###tab<id>`: ImGui keys a tab by the part after `###`, which a
  changing title must not move. The grid is a child window under the bar, so it scrolls
  alone; focus is asked of root and child (`FOCUSED_FLAGS_ROOT_AND_CHILD_WINDOWS`), and a
  frame whose keys were a tab shortcut gives the tab none.
- **On a Mac the menu bar is Sulafat's own** (`ui.install_menus`, through `bindings.menubar`),
  replacing SDL's, whose Window ▸ Close took ⌘W and closed the window — the app — not the
  tab. Shell holds New Tab ⌘T, Show Previous/Next Tab ⌘⇧[ ⌘⇧] (spelled `{` `}`, as AppKit
  matches shifted keys) and Close Tab ⌘W; they arrive through `poll_menu`, and
  `tab_command` leaves those keys alone when the bar is there, since AppKit hands a key
  equivalent to SDL too. ⌘1–⌘9 have no items and stay keys.
- **Off macOS Sulafat draws the same menus** (`ui.menu_bar`, ImGui's main menu bar): Sulafat
  (Settings…, Quit), Shell, Edit, and Window (Minimize, Maximize, the tabs). A choice
  answers the Mac's tag (`MENU_*`; a tab is `MENU_TAB + k`), so the loop carries out both
  bars' choices in one place; Quit, Minimize and Maximize are the host's, done in the bar.
  There the keys stay keys and an item only shows them (Ctrl+Shift+…, Ctrl+Z for Undo).
  The bar takes its height off the viewport's work area, which the terminal's window fills.
- **Edit's items are one path with their keys** (`EditAction`): `CommandLine.edit_action` at a
  prompt, and while a program runs only Paste, sent bracketed when the program set
  `?2004` (`session.pasted`). With the menu bar the command line leaves ⌘Z/⌘X/⌘C/⌘V/⌘A to
  it (`menu_keys`), and each frame greys what would do nothing (`Session.can`).
- **The screen answers questions through `replies`** (DA1, DA2, XTVERSION, DSR, DECRQM, the
  colour queries OSC 10/11/12), which a session writes to the program each frame; a check
  running a program on a PTY must answer them too (`vttest`'s `full_screen`).
- **The alternate screen keeps no scrollback and shows none**: lines leaving it are not
  history, and a session draws from the screen's first row while it is on (`base`). The main
  screen behind it is fitted on resize.
- **A wide rune is a cell and a `SPACER`**; writing over either half blanks the other, and a
  wide rune with one column left wraps first. Drawing puts a wide glyph on its two cells
  alone, centred. The command line lays runes out the same way (`editor.layout`, `cells_of`):
  a wide rune two columns, wrapped whole, a combining mark none.
- **A zero-width rune joins the cell before it** (`Screen.combine`): a cell's combining marks
  are the screen's `combining` table, and the bits of its `attrs` above `MARKS_SHIFT` say
  which run (`marks_of`, 0 for none) — so a cell stays four scalars and width, words and
  selection read its base rune as before. Drawing and copying put the marks after it; a
  marked cell is drawn alone, so a mark's own advance cannot move what follows.
- **A soft wrap is `WRAPPED` on a line's last cell**, set as the text goes on to the next
  line; a copy joins such a line to the next, its trailing blanks kept. Being a cell's bit
  it travels with the line through scrolls, scrollback and inserts, and a write or erase of
  that cell clears it.
- **Glyphs a family lacks come from fallback fonts** (`settings.fallback_fonts`: Arial
  Unicode or Noto Sans CJK, then Apple Symbols or DejaVu Sans), merged into every face
  (`bindings.imgui`'s `merge_font_file`). Colour emoji are not drawn: stb_truetype has no
  colour, and ImGui's 16-bit `ImWchar` reaches only the BMP.
- **The grid's selection is absolute lines and column boundaries** (`vt.Spot`), so it stays
  on its text as output scrolls. The mouse selects above the command line at a prompt, and
  with Shift when a program has asked for the mouse (`?1000`/`?1002`/`?1003`, SGR `?1006` or
  X10), which is otherwise told of it; on the alternate screen an unreporting program gets
  the wheel as arrows (`?1007`).
- **Erase at a pending wrap erases the last column**, as xterm does: a line exactly as wide as
  the screen followed by `\e[K` loses its last character (less's status on a long path).
- **Nothing blocks**: `Pty.read` is non-blocking and drained once a frame, at most
  `READS_PER_FRAME` reads, so a program that never stops writing cannot freeze the window.
- **Settings take at once and are kept when the mouse is let go**: a change rebuilds the
  theme (`ui.theme_of`), reloads the faces only when the family or file changed (ImGui keeps
  a face per file; its size is chosen as it is pushed), and is written to the file once no
  button is held, not every frame of a slider's drag. The file is read leniently — a
  setting missing or wrong keeps its default — and a theme named in it gives the colours a
  `colours` object does not. Programs asking the colours (OSC 10/11) are told the theme's.
- **Font families are found by file name** (`Mono`, `Code`, `Courier`, `Consol`, as
  capitalised; faces by `-Bold`/` Bold`/`Bold` suffixes), after the ones Sulafat knows by path
  (SF Mono, Menlo, DejaVu Sans Mono), whose files are not offered twice.
- **A colour is one `u32`** (`DEFAULT`, a palette index, or RGB — `vt/style.lyra`): the
  screen records what the program asked for; the theme decides what it looks like.
- **Erases and scrolls fill with the pen's background** (xterm's BCE, which
  `TERM=xterm-256color` promises), and nothing else of the pen.
- **Bold is a face when the family has one, else drawn twice a pixel apart** — SF Mono is
  one variable font. Bold italic falls back to the italic face drawn bold.
- **Lines are separate arrays** (`blank_line`): rows are written in place, and two rows
  sharing one array show each other's text.
- **A cell's width is measured over 100 characters**: ImGui's `CalcTextSize` rounds up to a
  whole pixel, which over one character put the cursor cells to the right of the text.
- **Read modifiers through `ui.held()`, never `io.key_ctrl()`/`key_super()`.** ImGui swaps
  Ctrl and ⌘ on macOS (`ConfigMacOSXBehaviors`), so its Ctrl is ⌘ there; a terminal needs
  the keys themselves. The headless host turns the swap off, so `uitest`'s
  `check_mac_modifiers` turns it back on to test what the real window does.
- **Keys**: ImGui's keyboard navigation is turned off (the arrows and Tab are the shell's);
  typed text arrives through `bindings.imgui`'s `request_text_input`/`typed_text`. ⌘ (Ctrl+Shift
  off macOS) is the terminal's own; Ctrl+letter is the control character.
- **At a prompt the command line is a box pinned to the window's foot**, as Warp has it: the
  shell's prompt (the `B` line's cells before the input column) on its first row, the
  editor from column 0 below, the completion menu opening upward (`Place.menu_above`, its
  foot `Place.lift` points over the text: just above the box). Both rows are set in
  `BOX_INSET` from the grid's sides, so the command wraps a few columns before the grid
  does. The grid draws only the lines above the prompt's, and the page counts the box's height so the
  last line rests on it at the bottom; the box is drawn opaque at the view's foot
  (`origin.y + scroll + avail.y`), wherever the view is scrolled, and grid clicks stop at
  its top. While a program runs there is no box. zsh's echo of the command still lands in
  the transcript as `prompt command`.
- **The command line is Sulafat's only between `B` and the next mark.** zsh and bash report
  `A`/`B`/`C`/`D` (OSC 133) through `shell/shell.lyra`'s hooks; at `B`, `Mode` becomes
  `AtPrompt(line, col)` and the editor is drawn from that cell, the shell's empty input
  hidden under it; any other mark is `Raw`. **A `B` where the command was just sent from is
  that prompt redrawn** (`Session.sent_from`) — bash's readline redraws its line on a paste
  of several lines, before `C` — and is not a new prompt. A shell without integration (a
  bash older than 4.4, another shell, a remote one over ssh) never reaches `AtPrompt` — a
  classic terminal.
- **bash is started `bash --rcfile <Sulafat's> -i`** — an rc file is read only by an
  interactive non-login shell — and the file reads what `bash -l` would (`/etc/profile`, then
  the first of `~/.bash_profile`, `~/.bash_login`, `~/.profile`). `D`, OSC 7 and `A` come
  from the front of `PROMPT_COMMAND`, `B` is added to the end of `PS1` from its back, `C`
  from `PS0`, once for what was entered (a paste of several lines is several commands to
  bash). Each hook hands back the `$?` it found. Type-ahead is read at the end of
  `PROMPT_COMMAND` with `read -n 1 -t`, which turns canonical mode off while it waits (`-t 0`
  sees only whole lines), and arrives just before `B`. Tab completion is zsh's only
  (`Integration.completes`).
- **Return sends the command as a bracketed paste, then `\r`**, so the shell's line editor
  takes several lines as one command and echoes it into the transcript where the editor
  was. The shell turns the mode on just *after* the `B` mark — a check that answers `B` at
  once must wait for it (`check_shell`).
- **The `B` mark is the end of `PS1`**, re-added at each prompt by a precmd hook that moves
  itself last, so a theme's own hook has built `PS1` first. A theme that redraws the
  prompt asynchronously is untested.
- **Tab completion is zsh's, run in the live shell.** Sulafat writes `caret\ntext` to the
  window's request file (`SULAFAT_COMPLETE_FILE`) and sends `\e[9898~`, bound (once the
  user's `.zshrc` has chosen emacs or vi keys) to a widget that loads it into `BUFFER`, runs
  `complete-word` with `compadd` captured, and reports matches as OSC 7770 (`b`,
  `m;prefix;insert;suffix;shown;description` percent-encoded, `e`) — none inserted, none
  listed. **Sulafat finds the word itself** (`editor.shell_word_at`, quotes and escapes
  included): inside quotes zsh measures positions with the quote removed. The answer for a
  line edited since the request is dropped. **Typing narrows the menu locally** from the
  list zsh gave (`CommandLine.narrow`, by exact start; ⌫ widens it), keeping the choice
  chosen; it closes when nothing is left, the word is typed in full, or the caret moves off. `compinit` is loaded only if the user's
  config has not, its dump in Sulafat's cache.
- **Keys typed while a command runs go to it; what it leaves unread is Sulafat's.** At each
  new line zsh's `zle-line-init` (Sulafat's, running the user's first) reads what is waiting
  — before zsh's own line editor would take it into a buffer hidden under Sulafat's — and
  reports it raw (OSC 7770 `t`). `ui.typed_lines` makes lines of it; at the prompt the first
  line ended by Return runs, as in any terminal, the next at the next prompt, and the
  unended rest goes into the editor.
- **Editor edits build new arrays** (undo snapshots share buffers); typing joins one undo
  step until a word ends, rune deletes join, word and line deletes stand alone.
- **ImGui's mouse is at -FLT_MAX when it is nowhere**: test before any cell arithmetic.
- **Gaps in Lyra or its bindings go in `../lyra/todo.md`**, as Sheliak's do.

## Plan

1. **M0 — a terminal (done 10/16)**: PTY, parser, monochrome grid, scrollback, keys, paste.
2. **M1 — a classic terminal (done 10/16)**: SGR colours and attributes, wide characters, the
   DEC private modes (alternate screen, cursor keys, autowrap, DECSCUSR, bracketed paste,
   mouse reporting, focus), device reports, selection and copy, Alt as Meta. vim, less and
   top run correctly (`vttest`'s `check_full_screen`).
3. **M2 — blocks**: the shell integration's marks (zsh's is in, with M3; bash's goes
   through `--rcfile`) — OSC 133 (`A` prompt, `B` command, `C` output, `D;status` end) and
   OSC 7 (directory). Each command becomes a block — command, directory, status, duration,
   its own output — drawn as a card; a full-screen program takes the whole window.
4. **M3 — the editor (begun 10/16, before M1 and the block cards)**: zsh's integration,
   then the command line as Sulafat's editor — multi-line, soft wrap, the mouse (click,
   drag, double-click a word, triple-click a line), word and line motions, undo, the
   clipboard, history from `~/.zsh_history`, Tab completion (zsh's own, in a menu); bash's
   integration (10/19), but its Tab completion. Next: bash's completion, syntax colouring,
   Ctrl+R history search.

Open work is in `todo.md`; finished work in `done.md`.
