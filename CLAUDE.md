# Termina — Project Context

Termina (γ Lyrae) is a terminal emulator written in Lyra, after Warp: commands and their
output as **blocks**, and a command line that edits like a text editor rather than a shell's
line editor. **Open source, MIT** (`LICENSE`); the repository is private until published, and
contributions are not being accepted yet. Lives in the Lyra workspace beside `lyra/`; the
workspace's `CLAUDE.md` rules apply here too. **macOS and Linux** — Windows waits on Lyra
(`pkg/abi` has no Windows convention, `std.io` is POSIX, and Windows' PTY is ConPTY).

## Commands

```bash
../lyra/build.sh            # the compiler, std/, bindings/ and lib/liblyra-{pty,imgui}.a
./build.sh                  # -> build/: termina (and Termina.app on macOS), vttest, uitest
build/termina               # the login shell ($SHELL -l) in a window of tabs: ⌘T new (in the
                            #    shown tab's directory), ⌘W close, ⌘1–⌘9, ⌘⇧[ ⌘⇧]; a tab
                            #    closes when its shell ends, the window with the last
build/termina CMD [ARG…]    # that program instead (as xterm -e), no integration — a test
                            #    script's colors, say, seen without typing
open build/Termina.app      # the same, as a Mac app
                            # Settings… (⌘,; Ctrl+, off macOS): font, size, spacing, colors —
                            #    kept in ~/.config/termina/settings.json ($XDG_CONFIG_HOME)
build/vttest                # parser, screen, editor, PTY, zsh and bash checks; exit 1 on a failure
SDL_VIDEODRIVER=dummy build/uitest   # the command line on a headless ImGui host, driven by
                            #    injected keys, typing and clicks (double-click included)
build/menutest              # the Mac's menu bar, installed and read back (SDL's real video
                            #    driver, no window)
../lyra/build/lui src/menus_view.lui     # regenerate a markup's module after editing it
                            #    (or `lui --watch src/*.lui`); build.sh refuses a stale one
./package.sh 0.2.0          # after build.sh: build/release/Termina-0.2.0-macos-arm64.zip, or
                            #    termina-0.2.0-linux-<arch>.tar.gz, SDL3 inside; with
                            #    TERMINA_APPIMAGE=1 on Linux, Termina-0.2.0-linux-<arch>.AppImage
git tag v0.2.0 && git push origin v0.2.0   # a release: built, checked and published by
                            #    .github/workflows/release.yml (macOS arm64, Linux x86_64
                            #    and arm64); Actions ▸ Release ▸ Run workflow is a dry run
```

## Releases

- **A tag is a release.** `release.yml` checks out lyra and tree-sitter-lyra at `main`
  (a dry run may name other refs) beside Termina, builds SDL3, lyra (Go's build cache
  cleared first: it does not hash the grammar's `#include`d parser, so a restored one
  builds lyra with the old grammar) and Termina, runs
  vttest, uitest and menutest, packages, and publishes the archives with the commits each
  was built from in the notes — a tag of Termina pins nothing of the compiler's.
- **SDL3 is built from source** (`tools/sdl3.sh`, lyra's pin — move the two together) and
  **travels with the program**: in `Termina.app/Contents/Frameworks` (found through
  `@rpath`), or in the archive's `lib/` (an rpath of `$ORIGIN/lib`, set by patchelf).
  Homebrew's is built for the Mac it runs on, and Ubuntu 24.04 has none.
- **Linux releases are an AppImage too**: the archive's directory as an AppDir (`AppRun` a
  link to the program, `assets/termina.desktop` and the icon beside it), made by
  appimagetool and its runtime as `tools/appimagetool.sh` pins them, SHA-256 checked. No
  sandbox — a Flatpak's would need the shell started on the host — and no
  `LD_LIBRARY_PATH`, so the shells Termina starts load nothing of its. Run extracted, not
  mounted, where there is no FUSE (`APPIMAGE_EXTRACT_AND_RUN`); an AppImage of another
  processor does not run under emulation, its header's magic tripping the emulator.
- **The Mac app runs on macOS 13 and later** (`MACOSX_DEPLOYMENT_TARGET`, read by clang,
  SDL3's CMake and ImGui's build). Linux archives run on glibc 2.39 and later (Ubuntu
  24.04's).
- **The Mac app is signed with a Developer ID and notarized** when the repository has the
  secrets below; without them, ad hoc, with a warning in the run and the release notes.
  `package.sh` does it from `TERMINA_SIGN_IDENTITY` and `TERMINA_NOTARY_*`: the hardened
  runtime with a secure timestamp, `notarytool` (its answer checked for `Accepted`, Apple's
  log printed otherwise) and the ticket stapled. **The bundled SDL3 is signed with the same
  identity**, or library validation refuses to load it ("different Team IDs").
  **Not the App Store**: its sandbox would confine the user's shell and everything run
  from it to the app's container.

  | secret | what |
  |---|---|
  | `MACOS_CERTIFICATE_P12` | the Developer ID Application certificate and its key, exported as `.p12`, base64 (`base64 -i cert.p12 \| gh secret set MACOS_CERTIFICATE_P12`) |
  | `MACOS_CERTIFICATE_PASSWORD` | the `.p12`'s password |
  | `NOTARY_KEY_P8` | an App Store Connect API key (Developer role), the `.p8` file's text (`gh secret set NOTARY_KEY_P8 < AuthKey_….p8`) |
  | `NOTARY_KEY_ID` | that key's id |
  | `NOTARY_ISSUER_ID` | the account's issuer id (App Store Connect ▸ Users and Access ▸ Integrations) |

- **What the app may ask for is its commands'**: macOS asks about a child process's
  camera, microphone, Apple Events, local network and folders as the app's that started it.
  `assets/Termina.entitlements` (signed into the app, not SDL3) lets the hardened runtime
  pass Apple Events, the microphone and the camera — without it they are refused with no
  prompt — and `build.sh`'s `Info.plist` gives every prompt its reason (those three, Local
  Network for `ssh` to a machine nearby, Desktop, Documents, Downloads, removable and
  network volumes). Full Disk Access is the user's to grant. A new kind of access a command
  needs is an entitlement there, if the hardened runtime gates it, and a usage string.

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
| `src/termina.lyra` | `main`: the ImGui host and the window's state (`App`), and `frame`: the tabs read, the menus and keys carried out, the window drawn; fonts |
| `package.sh`, `tools/sdl3.sh`, `tools/appimagetool.sh` | a release archive with SDL3 inside — the Mac app signed and notarized when given an identity and key, an AppImage on Linux — SDL3 built from source for it, and the pinned appimagetool (Releases, above) |
| `assets/` | the icon: `termina.svg` the source; `Termina.icns` (the app's) and `termina.png` made from it (`assets/README.md`); `Termina.entitlements`, what the signed app's commands may ask for (Releases, above) |
| `src/session/session.lyra` | one tab: its PTY, screen, `Mode` and command line; read each frame, drawn and given keys when shown |
| `src/ui/tabs.lyra` | the tab bar (reorderable, its order read back) and the tab shortcuts |
| `src/menus_view.lui` | the menus as `.lui` markup, one tree for both bars; `menus_view.lyra` is generated from it (edit the `.lui`) |
| `src/menus/menus.lyra` | the menus shown: installed in the Mac's bar (once, greyed each frame) or drawn as ImGui's main menu bar elsewhere |
| `src/menutest.lyra` | the menu bar installed and read back |
| `src/shell/shell.lyra` | shell integration (zsh's `.zshenv` through `ZDOTDIR`, bash's rc file through `--rcfile`): the marks, Tab's completion widget and its request file, the history files, what Return sends |
| `src/editor/editor.lyra` | the command line's editor — text, caret, selection, motions, words, undo, layout; **pure** |
| `src/editor/syntax.lyra` | the command line's syntax for coloring: each rune's kind (command, option, quoted, variable, operator, comment); **pure** |
| `src/ui/modifiers.lyra` | the modifier keys as pressed — ImGui's macOS Ctrl/⌘ swap undone |
| `src/ui/typeahead.lyra` | keys typed ahead, raw, made into lines (Backspace, Ctrl+U/W applied; escapes dropped) |
| `src/ui/command_line.lyra` | the editor at the prompt: keys and mouse into editor calls, history, the completion menu, drawing |
| `src/vt/parser.lyra` | bytes → `Action`s — Paul Williams' DEC parser; **pure**, keeps all state across reads |
| `src/vt/screen.lyra` | `Action`s → the cell grid, cursor, scroll region, scrollback ring |
| `src/vt/width.lyra` | how many cells a rune takes: 2 wide (CJK, emoji), 0 combining, 1 the rest |
| `src/vt/selection.lyra` | a selection on the screen and scrollback: its text, a word's span; **pure** |
| `src/vt/style.lyra` | a `Cell`'s colors and attributes, and SGR on the `Pen` that writes them; **pure** |
| `src/settings/settings.lyra` | the user's settings, the themes offered, the file (read leniently), the monospaced families found |
| `src/settings_view.lui` | the Settings tab as `.lui` markup — font family or file, size, spacing, theme (saved ones too), every color, bold as bright; `settings_view.lyra` is generated from it |
| `src/ui/settings_window.lyra` | the Settings tab drawn: the markup rendered and its events carried out (`carry_out`) |
| `src/ui/theme.lyra` | recorded colors → pixels: the theme's own pair, ANSI 16, xterm's 256; inverse, dim, hidden |
| `src/ui/grid.lyra` | a screen line drawn: background runs, text runs of one style, faces, underlines, strike |
| `src/vttest.lyra` | the checks: byte strings against actions and screens, the editor on text, real programs, zsh and bash on a PTY (each skipped, and said so, where not installed) |
| `src/uitest.lyra` | the command line on a headless host: injected input, the editor checked after |

- **A frame is `frame()`, over the module-level `app`**, called by `main`'s loop and by the
  host while the window is resized (`bindings.imgui`'s `set_redraw`, a `pub extern` called in
  `unsafe`), so the contents follow the edge as it is dragged — on macOS AppKit's
  resize loop holds the main thread inside `begin_frame` until the mouse is let go. **`app`
  is read after `begin_frame`**: the frames drawn during a resize run inside it, and a copy
  taken before would undo them, the terminals' parsed screens included. State a frame keeps
  is a field of `App`, never a local of `main`.
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
- **The menus are one tree** (`menus_view.lui`, built each frame), shown two ways by
  `menus/menus.lyra`; a choice is a `MenuChoice`, carried out in one place in the loop.
  An item's choice must not depend on the frame (Show Previous Tab, not the tab it was):
  the Mac's bar sends what it was installed with.
- **On a Mac the menu bar is Termina's own** (`menus.install_native`, through
  `bindings.menubar`), replacing SDL's, whose Window ▸ Close took ⌘W and closed the window —
  the app — not the tab. Installed once — its shape never changes there, the tabs being
  listed only in the drawn bar — and greyed each frame from the tree (`sync_native`). Shell
  holds New Tab ⌘T, Show Previous/Next Tab ⌘⇧[ ⌘⇧] (spelled `{` `}`, as AppKit matches
  shifted keys) and Close Tab ⌘W, and `tab_command` leaves those keys alone when the bar is
  there, since AppKit hands a key equivalent to SDL too. ⌘1–⌘9 have no items and stay keys.
  View holds the font's size — Default Font Size ⌘0, Bigger ⌘=, Smaller ⌘- — a point at a
  time within the settings' range, kept as any setting is (`FontBigger`, `FontSmaller`,
  `FontDefault`). The Window menu is macOS's standard one.
- **Off macOS Termina draws the same tree** (`menus.draw_menu_bar`, ImGui's main menu bar),
  with Quit in the Termina menu and a Window menu (Minimize, Maximize, the tabs, Alt+1–9).
  There the keys stay keys and an item only shows them (Ctrl+Shift+…, Ctrl+Z for Undo,
  Ctrl+PgUp/PgDn; the font's size Ctrl+Shift+= - 0, since Ctrl+- is readline's undo). The
  bar takes its height off the viewport's work area, which the terminal's window fills.
- **Edit's items are one path with their keys** (`EditAction`): `CommandLine.edit_action` at a
  prompt, and while a program runs only Paste, sent bracketed when the program set
  `?2004` (`session.pasted`). With the menu bar the command line leaves ⌘Z/⌘X/⌘C/⌘V/⌘A to
  it (`menu_keys`), and each frame greys what would do nothing (`Session.can`).
- **The screen answers questions through `replies`** (DA1, DA2, XTVERSION, DSR, DECRQM, the
  color queries OSC 10/11/12), which a session writes to the program each frame; a check
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
- **The terminal's text is hinted off macOS** (`bindings.imgui`'s `set_font_hinting`:
  FreeType for the fonts from files, the faces and their fallbacks): a Linux display is most
  often a pixel a point, where stb_truetype's unhinted stems straddle two columns and look
  soft. The interface — tabs, menus, settings — keeps ImGui's own font as stb_truetype
  draws it, hinted only where the cells are. A Mac draws text unhinted, and Termina there does
  too. Hinted advances are whole pixels, so a cell is.
- **Glyphs a family lacks come from fallback fonts** (`settings.fallback_fonts`: Arial
  Unicode or Noto Sans CJK, then Apple Symbols or DejaVu Sans), merged into every face
  (`bindings.imgui`'s `merge_font_file`). Color emoji are not drawn: stb_truetype has no
  color, and ImGui's 16-bit `ImWchar` reaches only the BMP.
- **A command is a block of the transcript** (`Session.blocks`, `Block`): `C` opens one
  from the last prompt's `A` line (`OutputStart(line)`), `D` closes it
  (`CommandEnd(status, line)`, its line the first the output did not write on). Drawn as a
  card: the input on the theme's input color, the output on its output color, rounded,
  with padding around each and a margin between cards; the duration and a failure's `exit N` over its
  first row's right end where the text leaves room, a red bar down a failed one's left.
- **On the main screen the grid ends at the rows in use** (`Screen.used_rows`: the cursor's
  row, or a lower one with anything on it): the blank rows below a running command's output
  would pad the page past the view, with the box and the cards' room, and the view, following
  the bottom, would scroll what was written — sudo's password prompt — out of sight. A
  full-screen program on the alternate screen has every row.
- **Rows are not evenly spaced: `Rows` is where every line goes** (`block_rows_layout`, a
  frame's gaps above lines, from the blocks). Everything that turns a line into a height
  or back — drawing, the cursor, selection, the first line in view, the page's height, the
  mouse — asks it (`y_of`, `y_above`, `line_at_y`); `i × cell.y` is wrong wherever blocks
  are. A program's mouse reports still count the screen's own rows: blocks put no gaps on
  the alternate screen, and a `clear` drops those on the main one. A screen
  erased whole on the main screen (`\e[2J`, `\e[J` from its first cell: `clear`, Ctrl+L)
  is the `Cleared(line)` mark, and the blocks on it go. None on the alternate screen.
- **The grid's selection is absolute lines and column boundaries** (`vt.Spot`), so it stays
  on its text as output scrolls. The mouse selects above the command line at a prompt, and
  with Shift when a program has asked for the mouse (`?1000`/`?1002`/`?1003`, SGR `?1006` or
  X10), which is otherwise told of it; on the alternate screen an unreporting program gets
  the wheel as arrows (`?1007`).
- **Erase at a pending wrap erases the last column**, as xterm does: a line exactly as wide as
  the screen followed by `\e[K` loses its last character (less's status on a long path).
- **Nothing blocks**: `Pty.read` is non-blocking and drained once a frame, at most
  `READS_PER_FRAME` reads, so a program that never stops writing cannot freeze the window.
- **Settings live in `~/.config/termina/settings.json`** (`$XDG_CONFIG_HOME` first); with
  none there, the file the terminal kept as Sulafat (`~/.config/sulafat/`, `OLD_NAME`) is
  read, and the next save writes the new one. The old file is left alone. **Colors are
  `colors` in it, read as `colours` where a file has no `colors`** (`colors_in`,
  `OLD_COLORS_KEY`): files from before 10/20 spelled them so, the current ones and each
  saved theme's.
- **Settings take at once and are kept when the mouse is let go**: a change rebuilds the
  theme (`ui.theme_of`), reloads the faces only when the family or file changed (ImGui keeps
  a face per file; its size is chosen as it is pushed), and is written to the file once no
  button is held, not every frame of a slider's drag. The file is read leniently — a
  setting missing or wrong keeps its default — and a theme named in it gives the colors a
  `colors` object does not. Programs asking the colors (OSC 10/11) are told the theme's.
- **A theme is every color Termina draws**, not only the grid's: the sections' input (the
  box, a block's prompt and command) and output, the input's text (where a program gave
  it no color: `Theme.for_input`, for the rows in view a block's input takes and the
  box's prompt), the tabs (a tab, under the pointer, shown —
  labelled in the text's color), and the command line's text, completion menu and chosen
  row. A theme names its text, background, cursor, selection, sections and ANSI sixteen;
  the rest is made from them (`settings.colors_of`), and a dark theme's sections lighten
  its background, a light one's darken it (`sections_of`). The settings edit each, and an
  edit makes the theme `Custom`. Only ImGui's own widgets — the settings' fields, the
  menus — keep ImGui's style.
- **The settings are a tab** (`ui.settings_panel` in `draw_window`), written as markup
  (`settings_view.lui`) whose every control is an event (`SettingsEvent`, `carry_out`):
  the sliders' values (the size made whole points), and each color by its field's name
  (`SetColor("tab_hovered", …)`, `settings.color_named`/`with_color`) or its ANSI index
  (`with_ansi`, into an array of its own — the one a theme's colors hold is shared by
  every copy of them). An edited color makes the theme `Custom`. The color groups stand side
  by side as the width allows (a wrapping `Row` of `Group`s, each its heading over a form
  of its own), wrapping to new lines in a narrow window; uitest draws it at both widths. Settings… opens a
  Settings tab at the tab bar's right end, out of the tabs' order (`TAB_ITEM_FLAGS_TRAILING`,
  as `+` is), and shows it; it fills the tabs' area in the interface's font. Its × or ⌘W
  while it is shown closes it; a terminal's tab chosen by a key or a click takes over. The
  terminals go on being read behind it.
- **The user's themes are saved in the settings file** (`Settings.themes`, `SavedTheme`):
  the colors under a name not Termina's own nor `Custom` (`can_save_as`; a saved one of
  that name replaced), listed after Termina's, deleted to `Custom` with the colors kept.
  A theme named in the file is looked for among them before Termina's.
- **Font families are found by file name** (`Mono`, `Code`, `Courier`, `Consol`, as
  capitalised; faces by `-Bold`/` Bold`/`Bold` suffixes), after the ones Termina knows by path
  (SF Mono, Menlo, DejaVu Sans Mono), whose files are not offered twice.
- **A color is one `u32`** (`DEFAULT`, a palette index, or RGB — `vt/style.lyra`): the
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
  its top. **While a command sent from it runs, the box stays, greyed**, showing the
  command's first line — the keys are the program's, as in any terminal — but not on the
  alternate screen, where a full-screen program has the window. zsh's echo of the command still lands in
  the transcript as `prompt command`.
- **The command line is Termina's only between `B` and the next mark.** zsh and bash report
  `A`/`B`/`C`/`D` (OSC 133) through `shell/shell.lyra`'s hooks; at `B`, `Mode` becomes
  `AtPrompt(line, col)` and the editor is drawn from that cell, the shell's empty input
  hidden under it; any other mark is `Raw`. **A `B` where the command was just sent from is
  that prompt redrawn** (`Session.sent_from`) — bash's readline redraws its line on a paste
  of several lines, before `C` — and is not a new prompt. A shell without integration (a
  bash older than 4.4, another shell, a remote one over ssh) never reaches `AtPrompt` — a
  classic terminal.
- **bash is started `bash --rcfile <Termina's> -i`** — an rc file is read only by an
  interactive non-login shell — and the file reads what `bash -l` would (`/etc/profile`, then
  the first of `~/.bash_profile`, `~/.bash_login`, `~/.profile`). `D`, OSC 7 and `A` come
  from the front of `PROMPT_COMMAND`, `B` is added to the end of `PS1` from its back, `C`
  from `PS0`, once for what was entered (a paste of several lines is several commands to
  bash). Each hook hands back the `$?` it found. Type-ahead is read at the end of
  `PROMPT_COMMAND` with `read -n 1 -t`, which turns canonical mode off while it waits (`-t 0`
  sees only whole lines), and arrives just before `B`.
- **Return sends the command as a bracketed paste, then `\r`**, so the shell's line editor
  takes several lines as one command and echoes it into the transcript where the editor
  was. The shell turns the mode on just *after* the `B` mark — a check that answers `B` at
  once must wait for it (`check_shell`).
- **The `A` mark is the start of `PS1` and `B` its end**, re-added at each prompt by a
  precmd hook that moves itself last (bash: the last of `PROMPT_COMMAND`), so a theme's own
  hook has built `PS1` first. `A` in `PS1`, not printed by the hook, falls where the prompt
  is drawn — after zsh's `PROMPT_SP`, partway along a line that output did not end — and
  carries that line and column (`PromptStart`). A theme that redraws the prompt
  asynchronously is untested.
- **The box shows the prompt from `A` to `B`**: up to `PROMPT_ROWS` lines (a prompt of
  several lines whole), the first from `A`'s column — output before it on that line stays
  in the grid, drawn up to there — and a right prompt (zsh's `RPROMPT`: what follows the
  input column on `B`'s line, the shell's own input being empty) right-aligned in the last
  row. An `A` repeated with its line (a redraw) does not clear `Session.sent_from`.
- **Tab completion is the shell's, run in the live shell.** Termina writes `caret\ntext` to
  the window's request file (`TERMINA_COMPLETE_FILE`) and sends `\e[9898~`, bound to a widget
  that reports matches as OSC 7770 (`b`, `m;prefix;insert;suffix;shown;description`
  percent-encoded, `e`) — none inserted, none listed. zsh's (bound once the user's `.zshrc`
  has chosen emacs or vi keys) loads the text into `BUFFER` and runs `complete-word` with
  `compadd` captured. bash's (`bind -x`, every keymap) splits the caret's command into
  words as readline does (`COMP_WORDBREAKS`: `--opt=val` completes `val`, `if=` kept as the
  prefix), and runs the command's compspec — loaded through bash-completion's `-D` loader
  when there is none yet — its `-F` function with `COMP_*` set and its other options
  through `compgen`, commands for the first word, file names failing all; a `compopt`
  stand-in notes `nospace`, `filenames` and the rest. **The function is given the word
  unquoted** (`COMP_WORDS`, `COMP_LINE` and `$2`): bash-completion quotes it again for
  `compgen`, counting on readline's dequoting too, which a widget does not have. bash's
  matches have no descriptions; file names are `%q`-quoted, a directory gets `/`. **Termina finds the word itself** (`editor.shell_word_at`, quotes and escapes
  included): inside quotes zsh measures positions with the quote removed. The answer for a
  line edited since the request is dropped. **Typing asks the shell again** (`refreshing`):
  its answer is the menu as given — a case-insensitive or substring `matcher-list`
  honoured — nothing put in; meanwhile the menu narrows locally (`CommandLine.narrow`, by
  start, case aside, kept when nothing starts so), keeping the choice chosen. It closes
  when the shell finds nothing, the word is typed in full, or the caret moves off. **A
  completion's `/` or space gives way** to the next key when that would double it or end
  the word (`suffix_left`): zsh's `AUTO_REMOVE_SLASH`. `compinit` is loaded only if the
  user's config has not, its dump in Termina's cache.
- **The command line is colored by its syntax** (`editor.kinds`, a small lexer that only
  ever chooses a color): commands, options, quoted text, variables, operators and comments,
  in the theme's ANSI green, cyan, yellow, magenta, blue and its faint grey. `$(…)` is
  lexed as a command line of its own.
- **Ctrl+R searches the history** (`CommandLine.searching`): the editor's text is the query,
  the menu — the box's width — the history's commands with it in them, case aside, each once,
  the newest last and chosen; ↑/Ctrl+R older, ↓/Ctrl+S newer, Return or Tab puts one in,
  Escape or Ctrl+G puts back what was there. A bash compspec's `-C` command is run as
  readline runs it.
- **Keys typed while a command runs go to it; what it leaves unread is Termina's.** At each
  new line zsh's `zle-line-init` (Termina's, running the user's first) reads what is waiting
  — before zsh's own line editor would take it into a buffer hidden under Termina's — and
  reports it raw (OSC 7770 `t`). `ui.typed_lines` makes lines of it; at the prompt the first
  line ended by Return runs, as in any terminal, the next at the next prompt, and the
  unended rest goes into the editor.
- **Editor edits build new arrays** (undo snapshots share buffers); typing joins one undo
  step until a word ends, rune deletes join, word and line deletes stand alone.
- **ImGui's mouse is at -FLT_MAX when it is nowhere**: test before any cell arithmetic.
- **Gaps in Lyra or its bindings go in `../lyra/todo.md`**, as Sheliak's do.

## Plan

1. **M0 — a terminal (done 10/16)**: PTY, parser, monochrome grid, scrollback, keys, paste.
2. **M1 — a classic terminal (done 10/16)**: SGR colors and attributes, wide characters, the
   DEC private modes (alternate screen, cursor keys, autowrap, DECSCUSR, bracketed paste,
   mouse reporting, focus), device reports, selection and copy, Alt as Meta. vim, less and
   top run correctly (`vttest`'s `check_full_screen`).
3. **M2 — blocks (begun 10/19)**: the shell integration's marks (zsh's and bash's) — OSC
   133 (`A` prompt, `B` command, `C` output, `D;status` end) and OSC 7 (directory). Each
   command is a block, drawn as a card — its input and output in the theme's colors,
   padded, with room between cards — its duration and a failure's status at its right, a
   red bar down a failed one. Next: selecting, copying and folding a block whole.
4. **M3 — the editor (begun 10/16, before M1 and the block cards)**: zsh's integration,
   then the command line as Termina's editor — multi-line, soft wrap, the mouse (click,
   drag, double-click a word, triple-click a line), word and line motions, undo, the
   clipboard, history from `~/.zsh_history`, Tab completion (zsh's own, in a menu); bash's
   integration and its completion, syntax coloring, Ctrl+R history search, prompts of
   several lines and right prompts in the box, the box kept, greyed, while a command runs
   (10/19).

Open work is in `todo.md`; finished work in `done.md`.
