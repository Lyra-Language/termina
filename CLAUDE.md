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
build/vttest                # parser, screen, editor, PTY and zsh checks; exit 1 on a failure
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
| `src/menutest.lyra` | the menu bar installed and read back |
| `src/shell/shell.lyra` | shell integration (zsh's `.zshenv`, through `ZDOTDIR`): the marks, Tab's completion widget and its request file, the history file, what Return sends |
| `src/editor/editor.lyra` | the command line's editor — text, caret, selection, motions, words, undo, layout; **pure** |
| `src/ui/modifiers.lyra` | the modifier keys as pressed — ImGui's macOS Ctrl/⌘ swap undone |
| `src/ui/typeahead.lyra` | keys typed ahead, raw, made into lines (Backspace, Ctrl+U/W applied; escapes dropped) |
| `src/ui/command_line.lyra` | the editor at the prompt: keys and mouse into editor calls, history, the completion menu, drawing |
| `src/vt/parser.lyra` | bytes → `Action`s — Paul Williams' DEC parser; **pure**, keeps all state across reads |
| `src/vt/screen.lyra` | `Action`s → the cell grid, cursor, scroll region, scrollback ring |
| `src/vt/style.lyra` | a `Cell`'s colours and attributes, and SGR on the `Pen` that writes them; **pure** |
| `src/ui/theme.lyra` | recorded colours → pixels: the theme's own pair, ANSI 16, xterm's 256; inverse, dim, hidden |
| `src/ui/grid.lyra` | a screen line drawn: background runs, text runs of one style, faces, underlines, strike |
| `src/vttest.lyra` | the checks: byte strings against actions and screens, the editor on text, real programs and zsh on a PTY |
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
- **Edit's items are one path with their keys** (`EditAction`): `CommandLine.edit_action` at a
  prompt, and while a program runs only Paste, sent bracketed when the program set
  `?2004` (`session.pasted`). With the menu bar the command line leaves ⌘Z/⌘X/⌘C/⌘V/⌘A to
  it (`menu_keys`), and each frame greys what would do nothing (`Session.can`).
- **Nothing blocks**: `Pty.read` is non-blocking and drained once a frame, at most
  `READS_PER_FRAME` reads, so a program that never stops writing cannot freeze the window.
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
- **The command line is Sulafat's only between `B` and the next mark.** zsh reports
  `A`/`B`/`C`/`D` (OSC 133) through `shell/shell.lyra`'s hooks; at `B`, `Mode` becomes
  `AtPrompt(line, col)` and the editor is drawn from that cell, the shell's empty input
  hidden under it; any other mark is `Raw`. A shell without integration (bash for now, a
  remote shell over ssh) never reaches `AtPrompt` — a classic terminal.
- **Return sends the command as a bracketed paste, then `\r`**, so the shell's line editor
  takes several lines as one command and echoes it into the transcript where the editor
  was. zsh turns the mode on just *after* the `B` mark — a check that answers `B` at once
  must wait for it (`check_zsh`).
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
2. **M1 — a classic terminal**: SGR colours (16, 256, 24-bit) and attributes (done 10/16); wide characters
   (a width table); the alternate screen (`?1049`), application cursor keys (`?1`), bracketed
   paste (`?2004`), mouse reporting (`?1000`/`?1006`), DECSCUSR; selection and copy. Done
   when vim, htop and less run correctly.
3. **M2 — blocks**: the shell integration's marks (zsh's is in, with M3; bash's goes
   through `--rcfile`) — OSC 133 (`A` prompt, `B` command, `C` output, `D;status` end) and
   OSC 7 (directory). Each command becomes a block — command, directory, status, duration,
   its own output — drawn as a card; a full-screen program takes the whole window.
4. **M3 — the editor (begun 10/16, before M1 and the block cards)**: zsh's integration,
   then the command line as Sulafat's editor — multi-line, soft wrap, the mouse (click,
   drag, double-click a word, triple-click a line), word and line motions, undo, the
   clipboard, history from `~/.zsh_history`, Tab completion (zsh's own, in a menu). Next:
   syntax colouring, Ctrl+R history search, bash's integration.

Open work is in `todo.md`; finished work in `done.md`.
