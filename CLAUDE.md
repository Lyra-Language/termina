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
build/sulafat               # the login shell ($SHELL -l) in a window; closes when it ends
open build/Sulafat.app      # the same, as a Mac app
build/vttest                # parser, screen, editor, PTY and zsh checks; exit 1 on a failure
SDL_VIDEODRIVER=dummy build/uitest   # the command line on a headless ImGui host, driven by
                            #    injected keys, typing and clicks (double-click included)
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
| `src/sulafat.lyra` | `main`: the ImGui host, the frame loop, `Mode`, drawing the grid, keys → bytes |
| `src/shell/shell.lyra` | shell integration (zsh's `.zshenv`, through `ZDOTDIR`), the history file, what Return sends |
| `src/editor/editor.lyra` | the command line's editor — text, caret, selection, motions, words, undo, layout; **pure** |
| `src/ui/command_line.lyra` | the editor at the prompt: keys and mouse into editor calls, history, drawing |
| `src/vt/parser.lyra` | bytes → `Action`s — Paul Williams' DEC parser; **pure**, keeps all state across reads |
| `src/vt/screen.lyra` | `Action`s → the cell grid, cursor, scroll region, scrollback ring |
| `src/vttest.lyra` | the checks: byte strings against actions and screens, the editor on text, real programs and zsh on a PTY |
| `src/uitest.lyra` | the command line on a headless host: injected input, the editor checked after |

- **The parser recognises, the screen acts.** Neither reads the other's input: the parser is
  tested on bytes alone, the screen on actions. A new sequence is a `Screen.csi`/`esc`/`osc`
  case and a `vttest` line.
- **Nothing blocks**: `Pty.read` is non-blocking and drained once a frame, at most
  `READS_PER_FRAME` reads, so a program that never stops writing cannot freeze the window.
- **Lines are separate arrays** (`blank_line`): rows are written in place, and two rows
  sharing one array show each other's text.
- **A cell's width is measured over 100 characters**: ImGui's `CalcTextSize` rounds up to a
  whole pixel, which over one character put the cursor cells to the right of the text.
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
- **Editor edits build new arrays** (undo snapshots share buffers); typing joins one undo
  step until a word ends, rune deletes join, word and line deletes stand alone.
- **ImGui's mouse is at -FLT_MAX when it is nowhere**: test before any cell arithmetic.
- **Gaps in Lyra or its bindings go in `../lyra/todo.md`**, as Sheliak's do.

## Plan

1. **M0 — a terminal (done 10/16)**: PTY, parser, monochrome grid, scrollback, keys, paste.
2. **M1 — a classic terminal**: SGR colours (16, 256, 24-bit) and attributes; wide characters
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
   clipboard, history from `~/.zsh_history`. Next: Tab completion, syntax colouring,
   Ctrl+R history search, bash's integration.

Open work is in `todo.md`.
