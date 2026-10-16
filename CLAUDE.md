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
./build.sh                  # -> build/: sulafat, vttest
build/sulafat               # the login shell ($SHELL -l) in a window; closes when it ends
build/vttest                # parser, screen and PTY checks, headless; exit 1 on a failure
```

## Architecture

```
shell ⇄ bindings.pty ──bytes──▶ vt.Parser ──[]Action──▶ vt.Screen ──▶ draw (ImGui DrawList)
            ▲                                                              │
            └──────────────────── keys (send_keys) ◀──────────────────────┘
```

| file | what |
|---|---|
| `src/sulafat.lyra` | `main`: the ImGui host, the frame loop, drawing the grid, keys → bytes |
| `src/vt/parser.lyra` | bytes → `Action`s — Paul Williams' DEC parser; **pure**, keeps all state across reads |
| `src/vt/screen.lyra` | `Action`s → the cell grid, cursor, scroll region, scrollback ring |
| `src/vttest.lyra` | the checks: byte strings against actions and screens, and real programs on a PTY |

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
- **Gaps in Lyra or its bindings go in `../lyra/todo.md`**, as Sheliak's do.

## Plan

1. **M0 — a terminal (done 10/16)**: PTY, parser, monochrome grid, scrollback, keys, paste.
2. **M1 — a classic terminal**: SGR colours (16, 256, 24-bit) and attributes; wide characters
   (a width table); the alternate screen (`?1049`), application cursor keys (`?1`), bracketed
   paste (`?2004`), mouse reporting (`?1000`/`?1006`), DECSCUSR; selection and copy. Done
   when vim, htop and less run correctly.
3. **M2 — blocks**: shell integration injected at spawn (zsh through `ZDOTDIR`, bash through
   `--rcfile`) emitting OSC 133 (`A` prompt, `B` command, `C` output, `D;status` end) and
   OSC 7 (directory). Each command becomes a block — command, directory, status, duration,
   its own output — drawn as a card; a full-screen program takes the whole window.
4. **M3 — the editor**: the command line is Sulafat's, not the shell's: multi-line, the
   mouse, selection, word and line motions, undo, the clipboard, soft wrap, history, syntax
   colouring, then completions. Return sends the whole command; while a command runs, keys
   go to it.

Open work is in `todo.md`.
